class CreateSite
  class DuplicateURLError < StandardError
    attr_reader :existing_site

    def initialize(existing_site)
      @existing_site = existing_site
      super 'Url is already in use.'
    end
  end

  def initialize(site, current_user, referral_token, promotional_code)
    @site = site
    @current_user = current_user
    @referral_token = referral_token
    @promotional_code = promotional_code
  end

  def call
    check_for_duplicate!
    create_site
    track_site_creation
    handle_referral_token
    detect_install_type
    change_subscription
    use_promo_code
  end

  private

  attr_reader :site, :current_user, :referral_token, :promotional_code

  def use_promo_code
    UsePromotionalCode.new(site, current_user, promotional_code).call
  end

  def change_subscription
    ChangeSubscription.new(site, subscription: 'free', schedule: 'monthly').call
  end

  def detect_install_type
    DetectInstallType.new(site).call
  end

  def handle_referral_token
    Referrals::HandleToken.run(user: current_user, token: referral_token)
  end

  def track_site_creation
    TrackEvent.new(:created_site, site: site, user: current_user).call
  end

  def create_site
    Site.transaction do
      site.owners << current_user
      site.save!
      site.create_default_rules
    end
  end

  def check_for_duplicate!
    existing_site = Site.by_url_for(current_user, url: site.url)
    raise DuplicateURLError, existing_site if existing_site
  end
end
