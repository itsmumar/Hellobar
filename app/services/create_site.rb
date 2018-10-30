class CreateSite
  class DuplicateURLError < StandardError
    attr_reader :existing_site

    def initialize(existing_site)
      @existing_site = existing_site
      super 'Url is already in use.'
    end
  end

  def initialize(site, user, cookies: {}, referral_token:)
    @site = site
    @user = user
    @cookies = cookies
    @referral_token = referral_token
  end

  # @return Site
  def call
    validate_site!
    check_for_duplicate!
    create_site
    track_site_creation
    track_site_count
    handle_referral_token
    detect_install_type
    change_subscription
    site
  end

  private

  attr_reader :site, :user, :cookies, :referral_token

  def change_subscription
    if promotional_signup? || affiliate_signup?
      plan = PromotionalPlan.new

      if affiliate_signup?
        partner = Partner.find_by(affiliate_identifier: user.affiliate_identifier)
        plan = partner&.partner_plan || Partner.default_partner_plan
      end

      AddTrialSubscription.new(
        site,
        subscription: plan.subscription_type,
        trial_period: plan.duration
      ).call

      return
    end

    ChangeSubscription.new(site, subscription: 'free', schedule: 'monthly').call
  end

  def promotional_signup?
    user.sites.count == 1 && cookies[:promotional_signup] == 'true'
  end

  def affiliate_signup?
    user.sites.count == 1 && user.affiliate_identifier
  end

  def detect_install_type
    DetectInstallType.new(site).call
  end

  def handle_referral_token
    Referrals::HandleToken.run(user: user, token: referral_token)
  end

  def track_site_creation
    TrackEvent.new(:created_site, site: site, user: user).call
  end

  def track_site_count
    TrackEvent.new(:updated_site_count, user: user).call
  end

  def validate_site!
    site.validate!
  end

  def create_site
    Site.transaction do
      site.owners << user
      site.save!
      site.create_default_rules
    end
  end

  def check_for_duplicate!
    existing_site = Site.by_url_for(user, url: site.url)
    raise DuplicateURLError, existing_site if existing_site
  end
end
