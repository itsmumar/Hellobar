require 'integration_helper'

feature "User can sign in", js: true do
  after { devise_reset }

  scenario "through email and password" do
    user = create(:user)
    site = create(:site, users: [user])

    visit new_user_session_path

    fill_in 'Your Email', with: user.email
    fill_in 'Password', with: user.password

    click_button 'Sign in'

    expect(page).to have_content('Sign Out')
  end

  scenario "through oauth" do
    user = create(:user)
    site = create(:site, users: [user])
    auth = user.authentications.create({
      provider: "google_oauth2",
      uid: "12345"
    })

    OmniAuth.config.add_mock(:google_oauth2, {:uid => '12345'})
    visit new_user_session_path

    click_link 'google-login-button'

    expect(page).to have_content('Sign Out')

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  scenario "and sign out" do
    login
    find('.header-user-wrapper .icon-dropdown').hover
    page.find(:xpath, "//a[@href='/users/sign_out']").click
    expect(page).to have_content('Signed out successfully')
  end

  scenario "user with no sites can sign out" do
    user = login
    user.sites.destroy_all

    visit new_site_path
    find('.header-user-wrapper .icon-dropdown').hover
    page.find(:xpath, "//a[@href='/users/sign_out']").click
    expect(page).to have_content('Signed out successfully')
  end
end
