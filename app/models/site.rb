require 'uri'
require 'billing_log'
require 'site_detector'
require 'queue_worker/queue_worker'

class Site < ActiveRecord::Base
  include QueueWorker::Delay

  has_many :rules, -> { order('rules.editable ASC, rules.id ASC') }, dependent: :destroy, inverse_of: :site
  has_many :site_elements, through: :rules, dependent: :destroy
  has_many :site_memberships, dependent: :destroy
  has_many :owners, -> { where(role: 'owner') }, through: :site_memberships
  has_many :users, through: :site_memberships
  has_many :identities, dependent: :destroy
  has_many :contact_lists, dependent: :destroy
  has_many :subscriptions, -> { order 'id' }
  accepts_nested_attributes_for :subscriptions

  has_many :bills, -> { order 'id' }, through: :subscriptions
  has_many :image_uploads, dependent: :destroy
  has_many :autofills, dependent: :destroy

  acts_as_paranoid

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
    !@needs_script_regeneration.nil?
  end

  def regenerate_script
    @needs_script_regeneration = true unless destroyed?
  end

  # We are getting bad analytics data regarding installs and uninstalls
  # When I analyzed the data the samples were 90-99% inaccurate. Looking
  # at the code I can not see any obvious error. I'm adding this logging
  # to collect more data so that hopefully I can find the source of the
  # problem and then implement an appropriate fix.
  def debug_install(type)
    lines = ["[#{ Time.now }] #{ type } - Site[#{ id }] script_installed_at: #{ script_installed_at.inspect }, script_uninstalled_at: #{ script_uninstalled_at.inspect }, lifetime_totals: #{ @lifetime_totals.inspect }"]
    caller[0..4].each do |line|
      lines << "\t#{ line }"
    end

    File.open(Rails.root.join('log', 'debug_install.log'), 'a') do |file|
      file.puts(lines.join("\n"))
    end
  end

  # check and report whether script is installed, recording timestamp and tracking event if status has changed
  def script_installed?
    if !script_installed_db? && (script_installed_api? || script_installed_on_homepage?)
      store_script_installation!
    elsif script_installed_db? && !(script_installed_api? || script_installed_on_homepage?)
      store_script_uninstallation!
    end

    script_installed_db?
  end

  def store_script_installation!
    debug_install('INSTALLED')
    update(script_installed_at: Time.current)
    Referrals::RedeemForRecipient.run(site: self)
    Analytics.track(:site, id, 'Installed')
    onboarding_track_script_installation!
  end

  def onboarding_track_script_installation!
    owners.each do |user|
      user.onboarding_status_setter.installed_script!
    end
  end

  def store_script_uninstallation!
    debug_install('UNINSTALLED')
    update(script_uninstalled_at: Time.current)
    Analytics.track(:site, id, 'Uninstalled')
    onboarding_track_script_uninstallation!
  end

  def onboarding_track_script_uninstallation!
    owners.each do |user|
      user.onboarding_status_setter.uninstalled_script!
    end
  end

  # is the site's script installed according to the db timestamps?
  def script_installed_db?
    script_installed_at.present? && (script_uninstalled_at.blank? || script_installed_at > script_uninstalled_at)
  end

  # has the script been installed according to the API?
  def script_installed_api?(days = 10)
    data = lifetime_totals(days: days)
    return false unless data.present?

    has_new_views = data.values.any? do |values|
      days_with_views = values.select { |v| v[0] > 0 }.count

      (days_with_views < days && days_with_views > 0) ||            # site element was installed in the last n days
        (values.count >= days && values[-days][0] < values.last[0]) # site element received views in the last n days
    end

    has_new_views
  end

  def script_installed_on_homepage?
    response = HTTParty.get(url, timeout: 5)
    if response =~ /#{script_name}/
      true
    elsif had_wordpress_bars? && response =~ /hellobar.js/
      true
    else
      false
    end
  rescue
    return false
  end

  def script_url
    if Hellobar::Settings[:store_site_scripts_locally]
      "generated_scripts/#{ script_name }"
    elsif Hellobar::Settings[:script_cdn_url].present?
      "#{ Hellobar::Settings[:script_cdn_url] }/#{ script_name }"
    else
      "#{ Hellobar::Settings[:s3_bucket] }.s3.amazonaws.com/#{ script_name }"
    end
  end

  def script_name
    raise 'script_name requires ID' unless persisted?
    "#{ Site.id_to_script_hash(id) }.js"
  end

  def script_content(compress = true)
    ScriptGenerator.new(self, compress: compress).generate_script
  end

  def generate_script(options = {})
    if options[:immediately]
      generate_static_assets(options)
    else
      delay :generate_static_assets, options
    end
  end

  def generate_script_and_check_installation(options = {})
    delay :do_generate_script_and_check_installation, options
  end

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
    subscriptions.active.to_a.sort.first
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
      bill = calculate_bill(subscription, true, trial_period)
      bill.save!
      subscription.save!

      if bill.due_at(payment_method) <= Time.now
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

  def preview_change_subscription(subscription)
    bill = calculate_bill(subscription, false)
    # Make the bill read-only
    def bill.readonly?
      true
    end
    bill
  end

  def bills_with_payment_issues(clear_cache = false)
    if clear_cache || !@bills_with_payment_issues
      now = Time.now
      @bills_with_payment_issues = []
      bills(true).each do |bill|
        # Find bills that are due now and we've tried to bill
        # at least once
        if bill.pending? && bill.amount > 0 && (now >= bill.bill_at) && !bill.billing_attempts.empty?
          @bills_with_payment_issues << bill
        end
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
    users.where("site_memberships.role = 'admin' OR site_memberships.role = 'owner'")
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

  def settings
    JSON.parse(self[:settings])
  rescue
    return {}
  end

  def update_content_upgrade_styles!(style_params)
    site_settings = settings
    site_settings['content_upgrade'] = style_params

    update_attribute(:settings, site_settings.to_json)
  end

  def content_upgrade_styles
    return JSON.parse(settings)['content_upgrade']
  rescue
    return {}
  end

  private

  # Calculates a bill, but does not save or pay the bill. Used by
  # change_subscription and preview_change_subscription
  def calculate_bill(subscription, actually_change, trial_period = nil)
    raise MissingSubscription unless subscription
    now = Time.now
    # First we need to void any pending recurring bills
    # and keep any active paid bills
    active_paid_bills = []
    bills(true).each do |bill|
      if bill.is_a?(Bill::Recurring)
        if bill.pending?
          bill.void! if actually_change
        elsif bill.paid?
          active_paid_bills << bill if bill.active_during(now)
        end
      end
    end
    if actually_change
      audit << "Changing subscription to #{ subscription.inspect }"
    end
    bill = Bill::Recurring.new(subscription: subscription)
    if active_paid_bills.empty?
      # Gotta pay full amount now
      bill.amount = subscription.amount
      bill.grace_period_allowed = false
      bill.bill_at = now
      if actually_change
        audit << "No active paid bills, charging full amount now: #{ bill.inspect }"
      end
    else
      last_subscription = active_paid_bills.last.subscription
      if Subscription::Comparison.new(last_subscription, subscription).upgrade?
        # We are upgrading, gotta pay now, but we prorate it

        bill.bill_at = now
        bill.grace_period_allowed = false
        # Figure out percentage of their subscription they've used
        # rounded to the day
        num_days_used = (now - active_paid_bills.last.start_date) / 1.day
        total_days_of_last_subcription = (active_paid_bills.last.end_date - active_paid_bills.last.start_date) / 1.day
        percentage_used = num_days_used.to_f / total_days_of_last_subcription
        percentage_unused = 1.0 - percentage_used
        if actually_change
          audit << "now: #{ now }, start_date: #{ active_paid_bills.last.start_date }, end_date: #{ active_paid_bills.last.end_date }, total_days_of_last_subscription: #{ total_days_of_last_subcription.inspect }, num_days_used: #{ num_days_used }, percentage_unused: #{ percentage_unused }"
        end

        unused_paid_amount = last_subscription.amount * percentage_unused
        # Subtract the unused paid amount from the price and round it
        bill.amount = (subscription.amount - unused_paid_amount).to_i
        if actually_change
          audit << "Upgrade from active bill: #{ active_paid_bills.last.inspect } changing from subscription #{ active_paid_bills.last.subscription.inspect }, prorating amount now: #{ bill.inspect }"
        end
      else
        # We are downgrading or staying the same, so just set the bill to start
        # after this bill ends, but make it the full amount
        bill.bill_at = active_paid_bills.last.end_date
        bill.amount = subscription.amount
        bill.grace_period_allowed = true
        if actually_change
          audit << "Downgrade from active bill: #{ active_paid_bills.last.inspect } changing from subscription #{ active_paid_bills.last.subscription.inspect }, charging full amount later: #{ bill.inspect }"
        end
      end
    end
    bill.start_date = bill.bill_at - 1.hour
    bill.end_date = bill.renewal_date

    if trial_period
      bill.amount = 0
      bill.end_date = Time.now + trial_period
    end

    bill
  end

  def do_generate_script_and_check_installation(options = {})
    generate_static_assets(options)
    script_installed?
  end

  def do_check_installation(_options = {})
    script_installed?
  end

  def generate_static_assets(options = {})
    update_column(:script_attempted_to_generate_at, Time.now)

    store_site_scripts_locally = Hellobar::Settings[:store_site_scripts_locally]
    compress_script = !store_site_scripts_locally

    generated_script_content = options[:script_content] || script_content(compress_script)

    if store_site_scripts_locally
      File.open(Rails.root.join('public', 'generated_scripts', script_name), 'w') { |f| f.puts(generated_script_content) }
    else
      Hello::AssetStorage.new.create_or_update_file_with_contents(script_name, generated_script_content)

      site_elements.each do |site_element|
        next unless site_element.wordpress_bar_id
        users.each do |user|
          if user.wordpress_user_id
            name = "#{ user.wordpress_user_id }_#{ site_element.wordpress_bar_id }.js"
            Hello::AssetStorage.new.create_or_update_file_with_contents(name, generated_script_content)
          end
        end
      end
    end

    update_column(:script_generated_at, Time.now)
  end

  def generate_blank_static_assets
    generate_static_assets(script_content: '')
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
