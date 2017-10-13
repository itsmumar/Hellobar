require 'integration_helper'

feature 'User sign ups with a referral token', :js do
  given(:email) { 'user@example.com' }
  given(:sender) { create :user }
  given(:referral_token) { create :referral_token, tokenizable: sender }
  given!(:senders_site) { create :site, user: sender }
  given(:recipients_site) { Site.last }
  given(:referral) { Referral.last }

  before do
    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: email })
    allow_any_instance_of(GenerateStaticScriptModules).to receive(:call)
    allow_any_instance_of(RenderStaticScript)
      .to receive(:call).and_return('function hellobar(){}')

    create :coupon, :referral
  end

  background do
    visit accept_referrals_path(token: referral_token.token)

    fill_in 'site[url]', with: 'hellobar.com'
    click_on 'sign-up-button'

    click_on "I'll create it later - take me back"
  end

  scenario 'both recipient and sender get pro subscription' do
    expect(recipients_site).to be_capable_of :free
    expect(senders_site).to be_capable_of :free

    expect {
      UpdateStaticScriptInstallation.new(recipients_site, installed: true).call
    }.to change(CouponUse, :count).by 2

    expect(recipients_site).to be_capable_of :pro
    expect(senders_site).to be_capable_of :pro

    expect(referral.redeemed_by_sender_at).to be_present
    expect(referral.redeemed_by_recipient_at).to be_present
  end
end
