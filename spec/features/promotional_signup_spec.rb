feature 'Promotional signup', :js do
  context 'when using email and password' do
    scenario 'adds 30 days of Growth trial', freeze: '2018-06-24T14:00 UTC' do
      visit '/'

      set_promotional_signup_cookie

      visit users_sign_up_path

      fill_in 'registration_form[site_url]', with: 'site.com'

      fill_in 'registration_form[email]', with: 'email@example.com'
      fill_in 'registration_form[password]', with: 'password123'
      check 'registration_form[accept_terms_and_conditions]'

      first('[name=signup_with_email]').click

      expect(page).to have_content 'I’ll do this later'

      click_on 'I’ll do this later, take me to my dashboard'

      expect(page).to have_content 'Settings'
      click_on 'Settings'

      expect(page).to have_content 'Enter Payment Info'
      expect(page).to have_content '2018-07-24'
    end
  end

  context 'when using Google OAuth' do
    given(:email) { 'bob@lawblog.com' }

    scenario 'adds 30 days of Growth trial', freeze: '2018-06-24T14:00 UTC' do
      OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: email })

      visit '/'

      set_promotional_signup_cookie

      visit users_sign_up_path

      fill_in 'registration_form[site_url]', with: 'site.com'

      check 'registration_form[accept_terms_and_conditions]'

      first('[name=signup_with_google]').click

      expect(page).to have_content 'I’ll do this later, take me to my dashboard'

      click_on 'I’ll do this later, take me to my dashboard'

      expect(page).to have_content 'Settings'
      click_on 'Settings'

      expect(page).to have_content 'Enter Payment Info'
      expect(page).to have_content '2018-07-24'

      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end
  end

  context 'when cc cookie is set' do
    let(:credit_card_attributes) { build(:payment_form_params) }

    before { stub_cyber_source :store, :purchase }

    it 'redirects to credit card page' do
      visit '/'

      set_promotional_signup_cookie
      set_cc_cookie

      visit users_sign_up_path

      fill_in 'registration_form[site_url]', with: 'site.com'

      fill_in 'registration_form[email]', with: 'email@example.com'
      fill_in 'registration_form[password]', with: 'password123'
      check 'registration_form[accept_terms_and_conditions]'

      first('[name=signup_with_email]').click

      expect(page).to have_content 'Billing Information'

      fill_in 'credit_card[name]', with: credit_card_attributes[:name]
      fill_in 'credit_card[number]', with: credit_card_attributes[:number]
      fill_in 'credit_card[expiration]', with: credit_card_attributes[:expiration]
      fill_in 'credit_card[verification_value]', with: credit_card_attributes[:verification_value]
      fill_in 'credit_card[address]', with: credit_card_attributes[:address]
      fill_in 'credit_card[city]', with: credit_card_attributes[:city]
      fill_in 'credit_card[state]', with: credit_card_attributes[:state]
      fill_in 'credit_card[zip]', with: credit_card_attributes[:zip]
      select 'Belarus', from: 'credit_card[country]'

      click_on 'Finish'

      expect(page).to have_content 'Step 1 is to choose your goal.'
    end
  end

  context 'when it is a dollar trial' do
    it 'should not say anything about after 30 days upgrade to annual' do
      visit '/'

      set_promotional_signup_cookie

      visit users_sign_up_path(utm_campaign: 'not_dollar_trial')

      expect(page).not_to have_content 'total: $1 for 30 days'
    end

    it 'should say after 30 days if the param is set' do
      visit '/'

      set_promotional_signup_cookie

      visit users_sign_up_path(utm_campaign: 'dollar_trial')

      expect(page).to have_content 'total: $1 for 30 days'
    end
  end

  private

  def set_promotional_signup_cookie
    add_cookie 'promotional_signup', 'true'
  end

  def set_cc_cookie
    add_cookie 'cc', '1'
  end

  def add_cookie(name, value)
    browser = Capybara.current_session.driver.browser
    browser.manage.add_cookie name: name, value: value
  end

  def set_dollar_trial_cookie
    add_cookie 'utm_campaign', 'dollar_trial'
  end
end
