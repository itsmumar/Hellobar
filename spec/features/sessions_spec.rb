require 'integration_helper'

feature 'User can sign up', :js do
  given(:email) { 'bob@lawblog.com' }
  given(:user) { create :user, email: email }
  given(:coupon) { create :coupon, :promotional }

  before do
    allow_any_instance_of(SiteElementSerializer)
      .to receive(:proxied_url2png).and_return('')
    allow_any_instance_of(ApplicationController)
      .to receive(:ab_variation)
      .with('Sign Up Button 2016-03-17')
      .and_return('original')
  end

  scenario 'through oauth, original homepage' do
    # force original variation
    allow_any_instance_of(WelcomeController).to receive(:ab_variation).and_return('original')

    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: user.email })
    visit root_path

    fill_in 'site[url]', with: 'mewgle.com'
    click_button 'sign-up-button'

    within('.header-user-wrapper') do
      find('.dropdown-wrapper').click
      expect(page).to have_content('Sign Out')
    end

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  scenario 'through oauth, variation homepage' do
    # force new variation
    allow_any_instance_of(WelcomeController).to receive(:ab_variation).and_return('variant')

    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: user.email })
    visit root_path

    first('input[name="site[url]"]').set 'mewgle.com'
    first('.login-with-google').click

    within('.header-user-wrapper') do
      find('.dropdown-wrapper').click
      expect(page).to have_content('Sign Out')
    end

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  scenario 'through oauth, using promotional code to have free Pro trial' do
    # force new variation
    allow_any_instance_of(WelcomeController).to receive(:ab_variation).and_return('variant')

    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: email })
    visit root_path

    first('input[name="site[url]"]').set 'mewgle.com'
    first('input[name="promotional_code"]').set coupon.label

    first('.login-with-google').click

    sleep 55 # TODO: investigate 40-50 seconds sign-up timeout

    expect(page).to have_content "I'll create it later"

    click_on "I'll create it later - take me back"

    expect(page).to have_content 'Enjoying Hello Bar Pro?'

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
    login

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
