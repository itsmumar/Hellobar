class CreateSite
  class DuplicateURLError < StandardError
    attr_reader :existing_site

    def initialize(existing_site)
      @existing_site = existing_site
      super 'Url is already in use.'
    end
  end

  def initialize(site, user, referral_token:)
    @site = site
    @user = user
    @referral_token = referral_token
  end

  # @return Site
  def call
    check_for_duplicate!
    create_site
    track_site_creation
    handle_referral_token
    detect_install_type
    change_subscription
    site
  end

  private

  attr_reader :site, :user, :referral_token

  def change_subscription
    ChangeSubscription.new(site, subscription: 'free', schedule: 'monthly').call
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
