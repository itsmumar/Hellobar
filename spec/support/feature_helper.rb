include Warden::Test::Helpers
Warden.test_mode!


module FeatureHelper
  def login(user=nil)
    user ||=  create(:user)
    unless user.sites.present?
      site = user.sites.create(url: random_uniq_url) # Setup a site so that it goes directly to summary page
    end

    login_as user, scope: :user, run_callbacks: false
    visit "/"
    user
  end

  def devise_reset
    Warden.test_reset!
  end

  def the_onboarding_campaigns_run
    UserOnboardingCampaign.deliver_all_onboarding_campaign_email!
  end
end
