class CreateSite
  def initialize(site, current_user, referral_token)
    @site = site
    @current_user = current_user
    @referral_token = referral_token
  end

  def call
    site.save!
    site.create_default_rules
    SiteMembership.create!(site: site, user: current_user)
    TrackEvent.new(:created_site, site: site, user: current_user).call

    Referrals::HandleToken.run(user: current_user, token: referral_token)
    ChangeSubscription.new(site, subscription: 'free', schedule: 'monthly').call
    DetectInstallType.new(site).call
    site.script.generate
  end

  private

  attr_reader :site, :current_user, :referral_token
end
