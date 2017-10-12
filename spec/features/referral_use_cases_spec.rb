require 'integration_helper'

feature 'Handling referrals', :js do
  given(:email) { 'user@example.com' }
  given(:user) { create :user }
  given(:referral_token) { create :referral_token, tokenizable: user }
  given(:last_site) { Site.last }

  before do
    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: email })
    allow_any_instance_of(GenerateStaticScriptModules).to receive(:call)
    allow_any_instance_of(RenderStaticScript)
      .to receive(:call).and_return('function hellobar(){}')

    Coupon.create! label: Coupon::REFERRAL_LABEL, amount: Coupon::REFERRAL_AMOUNT, public: false
  end

  scenario 'user creates site with referral token' do
    visit accept_referrals_path(token: referral_token.token)

    fill_in 'site[url]', with: 'hellobar.com'
    click_on 'sign-up-button'

    click_on "I'll create it later - take me back"

    expect(last_site).to be_capable_of :free

    UpdateStaticScriptInstallation.new(Site.last, installed: true).call

    expect(last_site).to be_capable_of :pro
  end
end
