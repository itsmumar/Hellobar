require 'billing_log'
require 'site_detector'
require 'queue_worker/queue_worker'

class Site < ActiveRecord::Base
  include QueueWorker::Delay

  has_many :rules, -> { order("editable ASC, id ASC") }, dependent: :destroy
  has_many :site_elements, through: :rules, dependent: :destroy
  has_many :site_memberships, dependent: :destroy
  has_many :users, through: :site_memberships
  has_many :identities, dependent: :destroy
  has_many :contact_lists, dependent: :destroy
  has_many :subscriptions, -> {order 'id'}
  has_many :bills, -> {order 'id'}, through: :subscriptions
  has_many :improve_suggestions
  acts_as_paranoid

  before_validation :standardize_url
  before_validation :generate_read_write_keys

  before_destroy :blank_out_script

  after_create do
    delay :set_install_type
  end

  validates :url, url: true
  validates :read_key, presence: true, uniqueness: true
  validates :write_key, presence: true, uniqueness: true

  scope :script_installed_db, -> do
    where("script_installed_at IS NOT NULL AND (script_uninstalled_at IS NULL OR script_installed_at > script_uninstalled_at)")
  end

  scope :script_uninstalled_db, -> do
    where("script_installed_at IS NOT NULL AND (script_uninstalled_at IS NULL OR script_installed_at > script_uninstalled_at)")
  end

  def owners
    site_memberships.select { |x| x.role == "owner" }.map(&:user)
  end

  # We are getting bad analytics data regarding installs and uninstalls
  # When I analyzed the data the samples were 90-99% inaccurate. Looking
  # at the code I can not see any obvious error. I'm adding this logging
  # to collect more data so that hopefully I can find the source of the
  # problem and then implement an appropriate fix.
  def debug_install(type)
    lines = ["[#{Time.now}] #{type} - Site[#{self.id}] script_installed_at: #{self.script_installed_at.inspect}, script_uninstalled_at: #{self.script_uninstalled_at.inspect}, lifetime_totals: #{@lifetime_totals.inspect}"]
    caller[0..4].each do |line|
      lines << "\t#{line}"
    end

    File.open(File.join(Rails.root, "log", "debug_install.log"), "a") do |file|
      file.puts(lines.join("\n"))
    end
  end

  # check and report whether script is installed, recording timestamp and tracking event if status has changed
  def has_script_installed?
    if !script_installed_db? && script_installed_api?
      debug_install("INSTALLED")
      update(script_installed_at: Time.current)
      Analytics.track(:site, self.id, "Installed")
    elsif script_installed_db? && !script_installed_api?
      debug_install("UNINSTALLED")
      update(script_uninstalled_at: Time.current)
      Analytics.track(:site, self.id, "Uninstalled")
    end

    script_installed_db?
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
      days_with_views = values.select{|v| v[0] > 0}.count

      (days_with_views < days && days_with_views > 0) ||            # site element was installed in the last n days
        (values.count >= days && values[-days][0] < values.last[0]) # site element received views in the last n days
    end
    return true if has_new_views
    # No new views, but if the script is installed and the site has site elements it might
    # just be a low traffic site
    return true if self.site_elements.length > 0 and script_installed_on_homepage?
    return false
  end

  def script_installed_on_homepage?
    response = HTTParty.get(self.url, timeout: 5)
    response =~ /#{script_name}/
  rescue
    return false
  end

  def script_url
    if Hellobar::Settings[:store_site_scripts_locally]
      "generated_scripts/#{script_name}"
    elsif Hellobar::Settings[:script_cdn_url].present?
      "#{Hellobar::Settings[:script_cdn_url]}/#{script_name}"
    else
      "#{Hellobar::Settings[:s3_bucket]}.s3.amazonaws.com/#{script_name}"
    end
  end

  def script_name
    raise "script_name requires ID" unless persisted?
    "#{Digest::SHA1.hexdigest("bar#{id}cat")}.js"
  end

  def script_content(compress = true)
    ScriptGenerator.new(self, :compress => compress).generate_script
  end

  def generate_script(options = {})
    delay :generate_static_assets, options
  end

  def generate_script_and_check_installation(options = {})
    delay :do_generate_script_and_check_installation, options
  end

  def check_installation(options = {})
    delay :do_check_installation, options
  end

=begin
  def recheck_installation(options = {})
    delay :do_recheck_installation, options
  end
=end

  def generate_improve_suggestions(options = {})
    delay :generate_all_improve_suggestions, options
  end

  def blank_out_script(options = {})
    delay :generate_blank_static_assets, options
  end

  def queue_digest_email(options = {})
    delay :send_digest_email, options
  end

  def send_digest_email(options = {})
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

  def create_default_rule
    rules.create!(:name => "Everyone", :match => Rule::MATCH_ON[:all], editable: false)
  end

  def current_subscription
    self.subscriptions.last
  end

  def url_exists?(user=nil)
    if user
      Site.joins(:users).where(url: url, users: {id: user.id}).where.not(id: id).any?
    else
      Site.where(url: url).where.not(id: id).any?
    end
  end

  def is_free?
    current_subscription.nil? ||
      current_subscription.type.blank? ||
      Subscription::Comparison.new(current_subscription, Subscription::Free.new).same_plan?
  end

  def capabilities(clear_cache=false)
    @capabilities = nil if clear_cache

    unless @capabilities
      # See if there are any active paid bills
      now = Time.now
      active_paid_bills = []
      bills(clear_cache).each do |bill|
        if bill.paid? and bill.is_a?(Bill::Recurring)
          if bill.active_during(now)
            active_paid_bills << bill
          end
        end
      end
      if active_paid_bills.empty?
        # Return the current subscription's capabilities if we
        # have one, otherwise just return the free plan capabilities
        @capabilities = (current_subscription ? current_subscription.capabilities : Subscription::Free::Capabilities.new(nil, self))
      else
        # Get the highest paid plan
        @capabilities = active_paid_bills.collect{|b| b.subscription}.sort.first.capabilities
      end
    end
    return @capabilities
  end

  def requires_payment_method?
    return false unless self.current_subscription
    return false if self.current_subscription.amount == 0
    return true
  end

  include BillingAuditTrail
  class MissingPaymentMethod < StandardError; end
  class MissingSubscription < StandardError; end
  def change_subscription(subscription, payment_method=nil, trial_period=nil)
    raise MissingSubscription.new unless subscription
    transaction do
      old_subscription = current_subscription
      subscription.site = self
      subscription.payment_method = payment_method
      success = true
      bill = calculate_bill(subscription, true, trial_period)
      now = Time.now
      if bill.due_at(payment_method) <= now
        audit << "Change plan, bill is due now: #{bill.inspect}"
        result = bill.attempt_billing!
        if result.is_a?(BillingAttempt)
          success = result.success?
        elsif result.is_a?(TrueClass) || result.is_a?(FalseClass)
          success = result
        else
          raise "Unexpected result: #{result.inspect}"
        end
      else
        audit << "Change plan, bill is due later: #{bill.inspect}"
      end
      bill.save!
      subscription.save!

      set_branding_on_site_elements

      return success, bill
    end
  end

  def preview_change_subscription(subscription)
    bill = calculate_bill(subscription, false)
    # Make the bill read-only
    def bill.readonly?
      return true
    end
    return bill
  end

  def bills_with_payment_issues(clear_cache=false)
    if clear_cache || !@bills_with_payment_issues
      now = Time.now
      @bills_with_payment_issues = []
      bills(true).each do |bill|
        # Find bills that are due now and we've tried to bill
        # at least once
        if bill.pending? and bill.amount > 0 and now >= bill.bill_at and bill.billing_attempts.length > 0
          @bills_with_payment_issues << bill
        end
      end
    end
    return @bills_with_payment_issues
  end

  def set_install_type
    update_attribute(:install_type, SiteDetector.new(url).site_type) unless Rails.env.test?
  end

  def self.in_bar_ads_config=(config)
    @in_bar_ads_config ||= {}
    @in_bar_ads_config.merge!(config)
  end

  def self.in_bar_ads_config
    {
      show_to_fraction: 0.1,
      test_fraction: (1.0/4.0),
      url_blacklist: ["iwillteachyoutoberich.com", "lewishowes.com"]
    }.merge(@in_bar_ads_config || {})
  end

  def show_in_bar_ads?
    config = self.class.in_bar_ads_config
    test_fraction   = config[:test_fraction]
    ad_blacklist    = config[:url_blacklist]
    site_ids        = config[:site_ids]

    if ad_blacklist.none? {|b| url.include?(b) }
      if is_free?
        if site_ids
          return site_ids.include?(id)
        elsif !Rails.env.production?
          return (test_fraction >= 1.0) || (id % (1 / test_fraction) == 0)
        end
      end
    end
    false
  end

  def membership_for_user(user)
    site_memberships.detect { |x| x.user_id == user.id }
  end

  def owners
    users.where(site_memberships: { role: Permissions::OWNER } )
  end

  private

  # Calculates a bill, but does not save or pay the bill. Used by
  # change_subscription and preview_change_subscription
  def calculate_bill(subscription, actually_change, trial_period=nil)
    raise MissingSubscription.new unless subscription
    now = Time.now
    # First we need to void any pending recurring bills
    # and keep any active paid bills
    active_paid_bills = []
    bills(true).each do |bill|
      if bill.is_a?(Bill::Recurring)
        if bill.pending?
          bill.void! if actually_change
        elsif bill.paid?
          if bill.active_during(now)
            active_paid_bills << bill
          end
        end
      end
    end
    if actually_change
      audit << "Changing subscription to #{subscription.inspect}"
    end
    bill = Bill::Recurring.new(subscription: subscription)
    if active_paid_bills.empty?
      # Gotta pay full amount now
      bill.amount = subscription.amount
      bill.grace_period_allowed = false
      bill.bill_at = now
      if actually_change
        audit << "No active paid bills, charging full amount now: #{bill.inspect}"
      end
    else
      last_subscription = active_paid_bills.last.subscription
      if Subscription::Comparison.new(last_subscription, subscription).upgrade?
        # We are upgrading, gotta pay now, but we prorate it

        bill.bill_at = now
        bill.grace_period_allowed = false
        # Figure out percentage of their subscription they've used
        # rounded to the day
        num_days_used = (now-active_paid_bills.last.start_date)/1.day
        total_days_of_last_subcription = (active_paid_bills.last.end_date-active_paid_bills.last.start_date)/1.day
        percentage_used = num_days_used.to_f/total_days_of_last_subcription
        percentage_unused = 1.0-percentage_used
        if actually_change
          audit << "now: #{now}, start_date: #{active_paid_bills.last.start_date}, end_date: #{active_paid_bills.last.end_date}, total_days_of_last_subscription: #{total_days_of_last_subcription.inspect}, num_days_used: #{num_days_used}, percentage_unused: #{percentage_unused}"
        end

        unused_paid_amount = last_subscription.amount*percentage_unused
        # Subtract the unused paid amount from the price and round it
        bill.amount = (subscription.amount-unused_paid_amount).to_i
        if actually_change
          audit << "Upgrade from active bill: #{active_paid_bills.last.inspect} changing from subscription #{active_paid_bills.last.subscription.inspect}, prorating amount now: #{bill.inspect}"
        end
      else
        # We are downgrading or staying the same, so just set the bill to start
        # after this bill ends, but make it the full amount
        bill.bill_at = active_paid_bills.last.end_date
        bill.amount = subscription.amount
        bill.grace_period_allowed = true
        if actually_change
          audit << "Downgrade from active bill: #{active_paid_bills.last.inspect} changing from subscription #{active_paid_bills.last.subscription.inspect}, charging full amount later: #{bill.inspect}"
        end
      end
    end
    bill.start_date = bill.bill_at
    bill.end_date = bill.renewal_date

    if trial_period
      bill.amount = 0
      bill.end_date = Time.now + trial_period
    end

    return bill
  end

  def do_generate_script_and_check_installation(options = {})
    generate_static_assets(options)
    has_script_installed?
  end

  def do_check_installation(options = {})
    has_script_installed?
  end

=begin
  def do_recheck_installation(options = {})
    # Check the script installation
    if self.has_script_installed?
      Analytics.track(:site, self.id, "Installed", at: self.script_installed_at)
    else
      if self.script_uninstalled_at
        Analytics.track(:site, self.id, "Uninstalled", at: self.script_uninstalled_at)
      end
    end
  end
=end

  def generate_static_assets(options = {})
    update_attribute(:script_attempted_to_generate_at, Time.now)

    Timeout::timeout(20) do
      generated_script_content = options[:script_content] || script_content(true)

      if Hellobar::Settings[:store_site_scripts_locally]
        File.open(File.join(Rails.root, "public/generated_scripts/", script_name), "w") { |f| f.puts(generated_script_content) }
      else
        Hello::AssetStorage.new.create_or_update_file_with_contents(script_name, generated_script_content)
      end
    end

    update_attribute(:script_generated_at, Time.now)
  end

  def generate_blank_static_assets
    generate_static_assets(:script_content => "")
  end

  def generate_all_improve_suggestions
    ImproveSuggestion.generate_all(self)
  end

  def standardize_url
    return if self.url.blank?

    url = Addressable::URI.heuristic_parse(self.url)
    self.url = "#{url.scheme}://#{url.normalized_host}"
  rescue Addressable::URI::InvalidURIError
    false
  end

  def generate_read_write_keys
    self.read_key = SecureRandom.uuid if self.read_key.blank?
    self.write_key = SecureRandom.uuid if self.write_key.blank?
  end

  def set_branding_on_site_elements
    site_elements.update_all(show_branding: !capabilities(true).remove_branding?)
  end
end
