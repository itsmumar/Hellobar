include Warden::Test::Helpers
Warden.test_mode!


module FeatureHelper
  def login
    user = create(:user)
    site = create(:site, users: [user]) # Setup a site so that it goes directly to summary page
    login_as user, scope: :user, run_callbacks: false
    visit "/"
    user
  end

  def devise_reset
    Warden.test_reset!
  end
end
