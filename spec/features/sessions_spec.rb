require 'integration_helper'

feature "User can sign up", js: true do
  after { devise_reset }

  scenario "through oauth" do
    OmniAuth.config.add_mock(:google_oauth2, {uid: '12345', info: {email: 'bob@lawblog.com'}})
    allow_any_instance_of(SiteElementSerializer).to receive(:proxied_url2png).and_return('')
    visit root_path

    fill_in 'site[url]', with: 'mewgle.com'
    click_button 'Log in with Google'

    expect(page).to have_content('Sign Out', visible: true)
    expect(page).to have_content('Use your Hello Bar to collect visitors', visible: true)
  end
end

feature "User can sign in", js: true do
  after { devise_reset }

  scenario "through email and password" do
    user = create(:user)
    site = user.sites.create(url: random_uniq_url)

    visit new_user_session_path

    fill_in 'Your Email', with: user.email
    click_button 'Continue'

    fill_in 'Password', with: user.password
    click_button 'Continue'

    #Why? because we cut off super long emails, that's why
    expect(page).to have_content(user.email[0...25])
  end

  scenario "through oauth" do
    user = create(:user)
    site = user.sites.create(url: random_uniq_url)
    auth = user.authentications.create({
      provider: "google_oauth2",
      uid: "12345"
    })

    OmniAuth.config.add_mock(:google_oauth2, {:uid => '12345'})
    visit new_user_session_path

    fill_in 'Your Email', with: user.email
    click_button 'Continue'

    #Why? because we cut off super long emails, that's why
    expect(page).to have_content(user.email[0...25])

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
