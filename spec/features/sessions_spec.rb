require 'integration_helper'

feature 'User can sign up', :js do
  given(:email) { 'bob@lawblog.com' }
  given(:user) { create :user, email: email }

  before do
    allow_any_instance_of(SiteElementSerializer)
      .to receive(:proxied_url2png).and_return('')
    allow_any_instance_of(ApplicationController)
      .to receive(:ab_variation)
      .with('Sign Up Button 2016-03-17')
      .and_return('original')

    allow_any_instance_of(RenderStaticScript)
      .to receive(:call).and_return('function hellobar(){}')
  end

  scenario 'through oauth' do
    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: email })
    visit root_path

    fill_in 'site_url', with: 'mewgle.com'

    click_on 'sign-up-button'

    first('[name=signup_with_google]').click

    expect(page).to have_content "I'll create it later"

    click_on "I'll create it later - take me back"

    within('.header-user-wrapper') do
      find('.dropdown-wrapper').click
      expect(page).to have_content('Sign Out')
    end

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  scenario 'with email/password' do
    visit root_path

    fill_in 'site_url', with: 'mewgle.com'

    click_on 'sign-up-button'

    fill_in 'user[email]', with: 'email@example.com'
    fill_in 'user[password]', with: 'password123'

    first('[name=signup_with_email]').click

    expect(page).to have_content "I'll create it later"

    click_on "I'll create it later - take me back"

    within('.header-user-wrapper') do
      find('.dropdown-wrapper').click
      expect(page).to have_content('Sign Out')
    end

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end

feature 'User can sign in', js: true do
  scenario 'through email and password' do
    user = create(:user, :with_site)

    visit new_user_session_path

    fill_in 'Your Email', with: user.email
    click_button 'Continue'

    fill_in 'Password', with: user.password
    click_button 'Continue'

    expect(page).to have_content('SELECT YOUR GOAL')
  end

  scenario 'through oauth' do
    user = create(:user, :with_site)
    user.authentications.create(provider: 'google_oauth2', uid: '12345')

    OmniAuth.config.add_mock(:google_oauth2, uid: '12345')
    visit new_user_session_path

    fill_in 'Your Email', with: user.email
    click_button 'Continue'

    expect(page).to have_content('SELECT YOUR GOAL')

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  scenario 'and sign out' do
    user = create :user, :with_site

    sign_in user

    find('.header-user-wrapper .dropdown-wrapper').click
    page.find(:xpath, "//a[@href='/users/sign_out']").click

    expect(page).to have_content('Signed out successfully')
  end

  scenario 'user with no sites can sign out' do
    user = create :user
    login_as user, scope: :user, run_callbacks: false

    visit root_path

    expect(page).to have_content 'Create A New Site'

    find('.header-user-wrapper .dropdown-wrapper').click
    find(:xpath, "//a[@href='/users/sign_out']").click

    expect(page).to have_content('Signed out successfully')
  end
end
