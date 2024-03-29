feature 'User sign ups with a referral token', :js do
  given(:email) { 'user@example.com' }
  given(:sender) { create :user }
  given(:referral_token) { create :referral_token, tokenizable: sender }
  given!(:senders_site) { create :site, user: sender }
  given(:recipients_site) { Site.last }
  given(:referral) { Referral.last }

  before do
    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: email })
    allow_any_instance_of(RenderStaticScript)
      .to receive(:call).and_return('function hellobar(){}')

    create :coupon, :referral
  end

  context 'when sender has only one site' do
    background do
      visit accept_referrals_path(token: referral_token.token)

      fill_in 'registration_form[site_url]', with: 'hellobars.com'
      check 'registration_form[accept_terms_and_conditions]'
      first('[name=signup_with_google]').click

      click_on 'I’ll do this later, take me to my dashboard'
    end

    scenario 'both recipient and sender get pro subscription' do
      expect(recipients_site).to be_capable_of :free
      expect(senders_site).to be_capable_of :free

      expect {
        UpdateStaticScriptInstallation.new(recipients_site, installed: true).call
      }.to change(CouponUse, :count).by 2

      expect(recipients_site).to be_capable_of :growth
      expect(senders_site).to be_capable_of :growth

      expect(referral.redeemed_by_sender_at).to be_present
      expect(referral.redeemed_by_recipient_at).to be_present
    end
  end

  context 'when sender has many sites' do
    given!(:sender_sites) { create_list :site, 3, user: sender }
    given(:random_sender_site) { sender_sites.sample }

    background do
      visit accept_referrals_path(token: referral_token.token)

      fill_in 'registration_form[site_url]', with: 'hellobars.com'
      check 'registration_form[accept_terms_and_conditions]'
      first('[name=signup_with_google]').click

      click_on 'I’ll do this later, take me to my dashboard'

      expect(recipients_site).to be_capable_of :free

      sender_sites.each do |site|
        expect(site).to be_capable_of :free
      end
    end

    scenario 'recipient get pro subscription instantly but sender have to apply it to a site manually' do
      expect {
        UpdateStaticScriptInstallation.new(recipients_site, installed: true).call
      }.to change(CouponUse, :count).by 1

      expect(recipients_site).to be_capable_of :growth

      expect(referral.redeemed_by_sender_at).to be_nil
      expect(referral.redeemed_by_recipient_at).to be_present

      sign_in_with(sender)

      visit referrals_path

      find('#referral_site_id').select random_sender_site.host
      expect(page).to have_content "Applied to #{ random_sender_site.host }"
      expect(CouponUse.count).to eql 2

      expect(random_sender_site).to be_capable_of :growth
      expect(referral.reload.redeemed_by_sender_at).to be_present
    end

    def sign_in_with(user)
      logout
      visit new_user_session_path

      fill_in 'Your Email', with: user.email
      click_button 'Continue'

      fill_in 'Password', with: user.password
      click_button 'Continue'
    end

    def logout
      find('.header-user-wrapper .dropdown-wrapper').click
      find(:xpath, "//a[@href='/users/sign_out']").click
    end
  end

  context 'when recipient signed up but does not install the script' do
    background do
      visit accept_referrals_path(token: referral_token.token)

      fill_in 'registration_form[site_url]', with: 'hellobars.com'
      click_on 'Create Your Free Account'
      check 'registration_form[accept_terms_and_conditions]'
      first('[name=signup_with_google]').click

      click_on 'I’ll do this later, take me to my dashboard'
    end

    scenario 'recipient sees announcement message on install page' do
      visit site_install_path(Site.last)

      expect(page).to have_content('Thanks for signing up! You’re currently on a free plan, in order to activate your 30 day trial of our Growth Plan')
    end
  end
end
