require 'uri'

class Site < ActiveRecord::Base
  DEFAULT_UPGRADE_STYLES = {
    'offer_bg_color' => '#ffffb6',
    'offer_text_color' => '#000000',
    'offer_link_color' => '#1285dd',
    'offer_border_color' => '#000000',
    'offer_border_width' => '0px',
    'offer_border_style' => 'solid',
    'offer_border_radius' => '0px',
    'modal_button_color' => '#1285dd'
  }.freeze

  attr_accessor :skip_script_generation

  has_many :rules, -> { order('rules.editable ASC, rules.id ASC') }, dependent: :destroy, inverse_of: :site
  has_many :site_elements, through: :rules, dependent: :destroy
  has_many :active_site_elements, through: :rules
  has_many :site_memberships, dependent: :destroy
  has_many :owners, -> { where(site_memberships: { role: 'owner' }) }, through: :site_memberships, source: :user
  has_many :owners_and_admins, -> { where(site_memberships: { role: %w[owner admin] }) }, through: :site_memberships, source: :user
  has_many :users, through: :site_memberships
  has_many :identities, dependent: :destroy
  has_many :contact_lists, dependent: :destroy
  has_many :subscriptions, -> { order 'id' }
  accepts_nested_attributes_for :subscriptions

  has_many :bills, -> { order 'id' }, through: :subscriptions, inverse_of: :site
  has_many :bills_with_payment_issues, -> { order(:bill_at).merge(Bill.problem) },
    class_name: 'Bill', through: :subscriptions, inverse_of: :site, source: :bills

  has_many :image_uploads, dependent: :destroy
  has_many :autofills, dependent: :destroy

  acts_as_paranoid

  scope :preload_for_script, lambda {
    preload(
      :site_elements, :active_site_elements,
      rules: [:conditions, :active_site_elements, :site_elements, site: :bills]
    )
  }

  before_validation :standardize_url
  before_validation :generate_read_write_keys

  before_destroy :generate_blank_static_assets

  after_update :regenerate_script
  after_touch  :regenerate_script

  after_commit do
    if needs_script_regeneration?
      generate_script
      generate_test_site
      @needs_script_regeneration = false
    end
  end

  validates :url, url: true
  validates :read_key, presence: true, uniqueness: true
  validates :write_key, presence: true, uniqueness: true

  validate :url_is_unique?

  store :settings, coder: JSON

  def self.protocol_ignored_url(url)
    host = normalize_url(url).normalized_host if url.include?('http')
    where('sites.url = ? OR sites.url = ?', "https://#{ host }", "http://#{ host }")
  end

  def self.script_installed_db
    where(
      'script_installed_at IS NOT NULL ' \
      'AND (script_uninstalled_at IS NULL OR script_installed_at > script_uninstalled_at)'
    )
  end

  def self.script_not_installed_db
    where.not(
      'script_installed_at IS NOT NULL ' \
      'AND (script_uninstalled_at IS NULL OR script_installed_at > script_uninstalled_at)'
    )
  end

  def self.script_uninstalled_db
    where(
      'script_installed_at IS NOT NULL ' \
      'AND (script_uninstalled_at IS NULL OR script_installed_at > script_uninstalled_at)'
    )
  end

  def self.script_was_installed_again
    where('script_uninstalled_at IS NOT NULL AND script_uninstalled_at > script_installed_at')
      .where('script_uninstalled_at > ? OR script_generated_at > script_uninstalled_at', 30.days.ago)
  end

  def self.id_to_script_hash(id)
    Digest::SHA1.hexdigest("bar#{ id }cat")
  end

  def self.find_by_script(script_embed)
    target_hash = script_embed.gsub(/^.*\//, '').gsub(/\.js$/, '')

    (Site.maximum(:id) || 1).downto(1) do |i|
      return Site.find_by(id: i) if id_to_script_hash(i) == target_hash
    end

    nil
  end

  def self.normalize_url(url)
    Addressable::URI.heuristic_parse(url)
  end

  def needs_script_regeneration?
    !skip_script_generation && @needs_script_regeneration.present?
  end

  def regenerate_script
    @needs_script_regeneration = true unless destroyed?
  end

  def script_installed?
    CheckStaticScriptInstallation.new(self).call

    script_installed_at.present? &&
      (script_uninstalled_at.blank? || script_installed_at > script_uninstalled_at)
  end

  def script_url
    if Settings.store_site_scripts_locally
      "generated_scripts/#{ script_name }"
    elsif Settings.script_cdn_url.present?
      "#{ Settings.script_cdn_url }/#{ script_name }"
    else
      "#{ Settings.s3_bucket }.s3.amazonaws.com/#{ script_name }"
    end
  end

  def script_name
    raise 'script_name requires ID' unless persisted?
    "#{ Site.id_to_script_hash(id) }.js"
  end

  def generate_script
    GenerateStaticScriptJob.perform_later self
  end

  def generate_test_site
    return unless Rails.env.development?

    Rails.logger.info "[HbTestSite] Generating static test site for Site##{ id }"
    HbTestSite.generate_default id
  end

  def lifetime_totals(opts = {})
    days = opts.delete(:days) || 7
    @lifetime_totals ||= {}

    if opts[:force] || @lifetime_totals[days].nil?
      @lifetime_totals[days] = Hello::DataAPI.lifetime_totals(self, site_elements, days, opts)
    else
      @lifetime_totals[days]
    end
  end

  def create_default_rules
    default_rules = rules.defaults
    default_rules.each(&:save!)

    default_rules.first
  end

  def custom_rules?
    rules.editable.any?
  end

  def current_subscription
    subscriptions.last
  end

  def previous_subscription
    subscriptions.offset(1).last
  end

  def pro_managed_subscription?
    subscriptions.any? { |s| s.class == Subscription::ProManaged }
  end

  def url_exists?(user = nil)
    if user
      Site.joins(:users)
          .merge(Site.protocol_ignored_url(url))
          .where(users: { id: user.id })
          .where.not(id: id)
          .any?
    else
      Site.where.not(id: id).merge(Site.protocol_ignored_url(url)).any?
    end
  end

  def url_is_unique?
    if users
       .joins(:sites)
       .merge(Site.protocol_ignored_url(url))
       .where.not(sites: { id: id })
       .any?

      errors.add(:url, 'is already in use')
    end
  end

  def free?
    current_subscription.nil? ||
      current_subscription.type.blank? ||
      Subscription::Comparison.new(current_subscription, Subscription::Free.new).same_plan?
  end

  # in case of downgrade user can have e.g Pro capabilities with Free subscription
  # when subscription ends up we return Free capabilities
  def capabilities
    active_subscription&.capabilities ||
      subscriptions.last&.capabilities ||
      Subscription::Free::Capabilities.new(nil, self)
  end

  def requires_payment_method?
    return false unless current_subscription
    return false if current_subscription.amount == 0
    true
  end

  def membership_for_user(user)
    site_memberships.find_by(user_id: user.id)
  end

  def had_wordpress_bars?
    site_elements.where.not(wordpress_bar_id: nil).any?
  end

  def normalized_url
    self.class.normalize_url(url).normalized_host || url
  rescue Addressable::URI::InvalidURIError
    url
  end

  def update_content_upgrade_styles!(style_params)
    update_attribute(:settings, settings.merge('content_upgrade' => style_params))
  end

  def content_upgrade_styles
    settings.fetch('content_upgrade', DEFAULT_UPGRADE_STYLES)
  end

  def active_paid_bill
    bills.paid.active.without_refunds.reorder(end_date: :desc, id: :desc).first
  end

  private

  def active_subscription
    active_paid_bill&.subscription
  end

  def generate_blank_static_assets
    GenerateAndStoreStaticScript.new(self, script_content: '').call
  end

  def standardize_url
    return if url.blank?
    normalized_url = self.class.normalize_url(url)
    self.url = "#{ normalized_url.scheme }://#{ normalized_url.normalized_host }"
  rescue Addressable::URI::InvalidURIError
    nil
  end

  def generate_read_write_keys
    self.read_key = SecureRandom.uuid if read_key.blank?
    self.write_key = SecureRandom.uuid if write_key.blank?
  end

  def set_branding_on_site_elements
    site_elements.update_all(show_branding: !capabilities.remove_branding?)
  end
end
