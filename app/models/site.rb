require 'uri'

class Site < ApplicationRecord
  COMMUNICATION_TYPES = %i[newsletter promotional partnership product research].freeze

  DEFAULT_UPGRADE_STYLES = {
    'offer_bg_color' => '#ffffb6',
    'offer_text_color' => '#000000',
    'offer_link_color' => '#1285dd',
    'offer_border_color' => '#000000',
    'offer_border_width' => '0px',
    'offer_border_style' => 'solid',
    'offer_border_radius' => '0px',
    'modal_button_color' => '#1285dd',
    'offer_font_size' => '15px',
    'offer_font_weight' => 'bold',
    'offer_font_family' => '\'Open Sans\',sans-serif',
    'offer_font_family_name' => 'Open Sans'
  }.freeze

  acts_as_paranoid

  has_one :whitelabel, dependent: :destroy
  has_many :rules, -> { order('rules.editable ASC, rules.id ASC') }, dependent: :destroy, inverse_of: :site
  has_many :site_elements, through: :rules, dependent: :destroy
  has_many :active_site_elements, through: :rules
  has_many :site_memberships, dependent: :destroy
  has_many :owners, -> { where(site_memberships: { role: 'owner' }) }, through: :site_memberships, source: :user
  has_many :admins, -> { where(site_memberships: { role: 'admin' }) }, through: :site_memberships, source: :user
  has_many :owners_and_admins, -> { where(site_memberships: { role: %w[owner admin] }) }, through: :site_memberships, source: :user
  has_many :users, through: :site_memberships
  has_many :identities, dependent: :destroy
  has_many :contact_lists, -> { order 'name' }, dependent: :destroy, inverse_of: :site
  has_many :subscriptions, -> { order 'id' }, dependent: :destroy, inverse_of: :site
  accepts_nested_attributes_for :subscriptions

  has_many :bills, -> { order 'id' }, through: :subscriptions, inverse_of: :site
  has_many :bills_with_payment_issues, -> { order(:bill_at).merge(Bill.failed) },
    class_name: 'Bill', through: :subscriptions, inverse_of: :site, source: :bills

  has_many :image_uploads, dependent: :destroy
  has_many :autofills, dependent: :destroy
  has_many :campaigns, dependent: :destroy, through: :contact_lists
  has_many :sequences, dependent: :destroy, through: :contact_lists
  has_many :coupon_uses, through: :bills
  has_many :emails, dependent: :destroy
  has_one :content_upgrade_styles, inverse_of: :site
  has_many :credit_cards, -> { order(:created_at).distinct }, through: :subscriptions

  scope :preload_for_script, lambda {
    preload(
      :site_elements, :active_site_elements,
      rules: [:conditions, :active_site_elements, :site_elements, site: :bills]
    )
  }

  scope :weekly_digest_optin, -> { where(opted_in_to_email_digest: true) }
  scope :by_url, ->(url) { protocol_ignored_url(url) }
  scope :active, -> { script_installed.joins(:site_elements).merge(SiteElement.active).distinct }

  before_validation :generate_read_write_keys

  validates :url, url: true
  validate :url, :check_for_banned_url, on: :create
  validates :terms_and_conditions_url, :privacy_policy_url, url: true, on: :update_privacy
  validates :read_key, presence: true, uniqueness: true
  validates :write_key, presence: true, uniqueness: true
  validates :communication_types, presence: true, on: :update_privacy
  validates :gdpr_consent_language, inclusion: { in: I18n.t('gdpr.languages').keys.map(&:to_s) }

  delegate :installed?, :name, :url, to: :script, prefix: true

  def self.recently_created
    where('created_at > ?', 30.days.ago)
  end

  def self.script_installed
    where(
      'script_installed_at IS NOT NULL ' \
      'AND (script_uninstalled_at IS NULL OR script_installed_at > script_uninstalled_at)'
    )
  end

  def self.script_not_installed
    where(
      'script_installed_at IS NULL ' \
      'OR (script_uninstalled_at IS NOT NULL AND script_uninstalled_at > script_installed_at)'
    )
  end

  def self.script_not_installed_but_active
    joins(:site_elements)
      .where(script_installed_at: nil)
      .where('site_elements.created_at > ?', 4.days.ago)
  end

  def self.script_uninstalled
    where('script_uninstalled_at > script_installed_at')
      .where.not(script_uninstalled_at: nil)
  end

  def self.script_recently_uninstalled
    script_uninstalled
      .where('script_uninstalled_at > ?', 30.days.ago)
  end

  def self.script_uninstalled_but_recently_modified
    script_uninstalled
      .where('script_generated_at > script_uninstalled_at')
      .where('script_generated_at > ?', 7.days.ago)
  end

  def self.protocol_ignored_url(url)
    host = Addressable::URI.heuristic_parse(url).normalized_host
    where(url: ["https://#{ host || url }", "http://#{ host || url }"])
  rescue Addressable::URI::InvalidURIError
    none
  end

  def self.by_url_for(user, url:)
    by_url(url).joins(:users).find_by(users: { id: user.id })
  end

  def views_limit
    capabilities.visit_overage
  end

  # rubocop:disable Delegate
  def visit_warning_one
    capabilities.visit_warning_one
  end

  def visit_warning_two
    capabilities.visit_warning_two
  end

  def visit_warning_three
    capabilities.visit_warning_three
  end

  def upsell_email_trigger
    capabilities.upsell_email_trigger
  end

  def upgrade_trigger
    capabilities.upgrade_trigger
  end
  # rubocop:enable Delegate

  def communication_types=(value)
    super(value.select(&:presence).join(','))
  end

  def communication_types
    self[:communication_types]&.split(',') || []
  end

  def url=(value)
    super(Addressable::URI.heuristic_parse(value)&.normalized_site || value)
  rescue Addressable::URI::InvalidURIError
    super(value)
  end

  def display_url
    display_uri&.to_s || url
  rescue Addressable::URI::InvalidURIError
    nil
  end

  def host
    display_uri&.host || url
  rescue Addressable::URI::InvalidURIError
    nil
  end

  def statistics
    @statistics ||= FetchSiteStatistics.new(self, days_limit: 7).call
  end

  def create_default_rules
    default_rules = rules.defaults
    default_rules.each(&:save!)

    default_rules.first
  end

  def custom_rules?
    rules.editable.any?
  end

  # Last subscription with excluded trials
  # meaning, it returns last subscription
  # even if it was refunded or has a due bill
  def current_subscription
    subscriptions.exclude_ended_trials.last
  end

  def previous_subscription
    subscriptions.offset(1).last
  end

  def free?
    current_subscription.nil? ||
      current_subscription.type.blank? ||
      current_subscription.free?
  end

  def pro_managed?
    current_subscription.is_a? Subscription::ProManaged
  end

  def growth?
    current_subscription.is_a? Subscription::Growth
  end
  
  def growth_or_pro?
    current_subscription.is_a?(Subscription::Growth) || current_subscription.is_a?(Subscription::Pro)
  end

  def elite?
    current_subscription.is_a? Subscription::Elite
  end

  # in case of downgrade user can have e.g Pro capabilities with Free subscription
  # when subscription ends up we return Free capabilities
  def capabilities
    active_subscription&.capabilities ||
      subscriptions.last&.capabilities ||
      Subscription::Free::Capabilities.new(nil, self)
  end

  def requires_credit_card?
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

  def content_upgrade_styles
    super || build_content_upgrade_styles(ContentUpgradeStyles::DEFAULT_STYLES)
  end

  def active_paid_bill
    bills.paid.active.reorder(end_date: :desc, id: :desc).first
  end

  # A paid, active subscription
  # returns nil if it was cancelled or refunded
  def active_subscription
    active_paid_bill&.subscription
  end

  def script
    @script ||= StaticScript.new(self)
  end

  def gdpr_enabled?
    communication_types? &&
      terms_and_conditions_url? &&
      privacy_policy_url?
  end

  def gdpr_consent
    topics = communication_types.map do |type|
      I18n.t(type, scope: 'gdpr.communication_types', locale: gdpr_consent_language)
    end

    topics = topics.to_sentence(locale: gdpr_consent_language)

    I18n.t('gdpr.consent', topics: topics, locale: gdpr_consent_language)
  end

  def gdpr_agreement
    I18n.t('gdpr.agreement',
      locale: gdpr_consent_language,
      privacy_policy_url: privacy_policy_url,
      terms_and_conditions_url: terms_and_conditions_url)
  end

  def gdpr_action
    I18n.t('gdpr.action', locale: gdpr_consent_language)
  end

  def self.banned_sites
    ['facebook.com', 'google.com', 'wordpress.com', 'hellobar.com', 'linkedin.com', 'mayvern.com', 'twitter.com', 'pintrest.com', 'youtube.com', 'google.com', 'yahoo.com', 'amazon.com', 'snapchat.com', 'instagram.com', 'gmail.com', 'plus.google.com', 'test.com', 'mail.google.com', 'zepo.com', 'vk.com', 'naver.com']
  end

  def self.url_error_messages(url)
    ["I, too, like to daydream that I own #{ url }. But I also like to imagine what the world would be like if a dog were president… Maybe it’s best if we’re realistic. Real URL, please?", "Fake news!!! #{ url } is not your URL! SAD!",
     "I call shenanigans! If #{ url } is your URL, then Neil has hair! Preposterous! Try again.",
     "Liar, liar, dungarees on fire! There’s no way #{ url } is your real URL. Try again!",
     "Hey now, this isn’t an online dating profile – no need to stretch the truth! What’s your real URL? Promise we won’t ghost you, even if you aren’t really the owner of #{ url }."].sample
  end

  def ab_test_not_running
    update(ab_test_running: false)
  end

  def ab_test_not_running!
    update!(ab_test_running: false)
  end

  def deactivate_site_element
    site_elements.active.each(&:deactivate)
    script.generate
  end

  def activate_site_element
    site_elements.deactivated.each(&:activate!)
    script.generate
  end

  def deactivated?
    site_elements.where.not(deactivated_at: nil).any?
  end

  def number_of_views
    # FetchTotalViewsForMonth.new([self]).call[id]
    3482
  end

  private

  def display_uri
    Addressable::URI.parse(url)&.display_uri
  end

  def generate_read_write_keys
    self.read_key = SecureRandom.uuid if read_key.blank?
    self.write_key = SecureRandom.uuid if write_key.blank?
  end

  def set_branding_on_site_elements
    site_elements.update_all(show_branding: !capabilities.remove_branding?)
  end

  def check_for_banned_url
    errors.add('ERROR:', Site.url_error_messages(url)) if url =~ URI::DEFAULT_PARSER.make_regexp && Site.banned_sites.include?(URI.parse(url).host.downcase.split('www.').last)
  end
end
