class CreateSite
  def initialize(site, current_user, referral_token)
    @site = site
    @current_user = current_user
    @referral_token = referral_token
  end

  def call
    create_site
    track_site_creation
    handle_referral_token
    detect_install_type
    change_subscription
  end

  private

  attr_reader :site, :current_user, :referral_token

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
end
