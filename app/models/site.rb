require 'uri'
require 'billing_log'
require 'site_detector'
require 'queue_worker/queue_worker'

class Site < ActiveRecord::Base
  include QueueWorker::Delay

  has_many :rules, -> { order('rules.editable ASC, rules.id ASC') }, dependent: :destroy, inverse_of: :site
  has_many :site_elements, through: :rules, dependent: :destroy
  has_many :active_site_elements, through: :rules
  has_many :site_memberships, dependent: :destroy
  has_many :owners, -> { where(role: 'owner') }, through: :site_memberships
  has_many :users, through: :site_memberships
  has_many :identities, dependent: :destroy
  has_many :contact_lists, dependent: :destroy
  has_many :subscriptions, -> { order 'id' }
  accepts_nested_attributes_for :subscriptions

  has_many :bills, -> { order 'id' }, through: :subscriptions, inverse_of: :site
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

  after_create do
    delay :set_install_type
  end

  after_update :regenerate_script
  after_touch  :regenerate_script

  after_commit do
    if needs_script_regeneration?
      generate_script
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
      'script_installed_at IS NOT NULL
      AND (script_uninstalled_at IS NULL OR script_installed_at > script_uninstalled_at)'
    )
  end

  def self.script_not_installed_db
    where.not(
      'script_installed_at IS NOT NULL
      AND (script_uninstalled_at IS NULL OR script_installed_at > script_uninstalled_at)'
    )
  end

  def self.script_uninstalled_db
    where(
      'script_installed_at IS NOT NULL
      AND (script_uninstalled_at IS NULL OR script_installed_at > script_uninstalled_at)'
    )
  end

  def needs_script_regeneration?
    @needs_script_regeneration.present?
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

  def script_content(compress = true)
    RenderStaticScript.new(self, compress: compress).call
  end

  # basically it calls rake site:generate_static_assets
  # @see lib/tasks/site.rake
  def generate_script(options = {})
    delay :generate_static_assets, options
  end

  # basically it calls rake site:do_generate_script_and_check_installation
  # @see lib/tasks/site.rake
  def generate_script_and_check_installation(options = {})
    delay :do_generate_script_and_check_installation, options
  end

  # basically it calls rake site:do_check_installation
  # @see lib/tasks/site.rake
  def check_installation(options = {})
    delay :do_check_installation, options
  end

  def queue_digest_email(options = {})
    delay :send_digest_email, options
  end

  def send_digest_email(_options = {})
    Hello::EmailDigest.send(self)
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
    rules.map(&:editable).any?
  end

  def current_subscription
    subscriptions.last
  end

  def highest_tier_active_subscription
    subscriptions.active.sort_by(&:significance).last
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

  def capabilities(clear_cache = false)
    @capabilities = nil if clear_cache
    @capabilities ||= highest_tier_active_subscription.try(:capabilities)
    @capabilities ||= subscriptions.last.try(:capabilities)
    @capabilities ||= Subscription::Free::Capabilities.new(nil, self)
  end

  def requires_payment_method?
    return false unless current_subscription
    return false if current_subscription.amount == 0
    true
  end

  include BillingAuditTrail

  class MissingPaymentMethod < StandardError; end
  class MissingSubscription < StandardError; end

  def change_subscription(subscription, payment_method = nil, trial_period = nil)
    raise MissingSubscription unless subscription
    transaction do
      subscription.site = self
      subscription.payment_method = payment_method
      success = true
      bill = calculate_bill(subscription, trial_period)
      bill.save!
      subscription.save!

      if bill.due_at(payment_method) <= Time.current
        audit << "Change plan, bill is due now: #{ bill.inspect }"
        result = bill.attempt_billing!
        if result.is_a?(BillingAttempt)
          success = result.success?
        elsif result.is_a?(TrueClass) || result.is_a?(FalseClass)
          success = result
        else
          raise "Unexpected result: #{ result.inspect }"
        end
      else
        audit << "Change plan, bill is due later: #{ bill.inspect }"
      end

      set_branding_on_site_elements

      return success, bill
    end
  end

  def bills_with_payment_issues(clear_cache = false)
    if clear_cache || !@bills_with_payment_issues
      @bills_with_payment_issues = []
      bills.due_now.each do |bill|
        # Find bills that are due now and we've tried to bill
        # at least once
        @bills_with_payment_issues << bill if bill.billing_attempts.present?
      end
    end
    @bills_with_payment_issues
  end

  def set_install_type
    update_attribute(:install_type, SiteDetector.new(url).site_type) unless Rails.env.test?
  end

  def self.normalize_url(url)
    Addressable::URI.heuristic_parse(url)
  end

  def membership_for_user(user)
    site_memberships.detect { |x| x.user_id == user.id }
  end

  def owners
    users.where(site_memberships: { role: Permissions::OWNER })
  end

  def owners_and_admins
    users.where("site_memberships.role = '#{ Permissions::OWNER }' OR site_memberships.role = '#{ Permissions::ADMIN }'")
  end

  def had_wordpress_bars?
    site_elements.where.not(wordpress_bar_id: nil).any?
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

  def normalized_url
    self.class.normalize_url(url).normalized_host || url
  rescue Addressable::URI::InvalidURIError
    url
  end

  def update_content_upgrade_styles!(style_params)
    update_attribute(:settings, settings.merge('content_upgrade' => style_params))
  end

  def content_upgrade_styles
    settings.fetch('content_upgrade', {})
  end

  private

  # Calculates a bill, but does not save or pay the bill. Used by
  # change_subscription
  def calculate_bill(subscription, trial_period = nil)
    raise MissingSubscription unless subscription
    CalculateBill.new(subscription, bills: bills.recurring, trial_period: trial_period).call
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
    site_elements.update_all(show_branding: !capabilities(true).remove_branding?)
  end
end
