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

      expect(page).to have_content "I'll create it later"

      click_on "I'll create it later - take me back"

      expect(page).to have_content 'Settings'
      click_on 'Settings'

      expect(page).to have_content 'Enjoying Hello Bar Growth?'
      expect(page).to have_content 'This site is on a trial plan. Please enter credit card details by 2018-07-24'
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

      expect(page).to have_content "I'll create it later"

      click_on "I'll create it later - take me back"

      expect(page).to have_content 'Settings'
      click_on 'Settings'

      expect(page).to have_content 'Enjoying Hello Bar Growth?'
      expect(page).to have_content 'This site is on a trial plan. Please enter credit card details by 2018-07-24'

      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end
  end

  private

  def set_promotional_signup_cookie
    browser = Capybara.current_session.driver.browser
    browser.manage.add_cookie name: 'promotional_signup', value: 'true'
  end
end
