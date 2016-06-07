require 'integration_helper'

feature "User can sign up", js: true do
  after { devise_reset }
  before do
    stub_out_get_ab_variations("Onboarding Limitted To Three Goals 2016-05-11") {"original"}
    allow_any_instance_of(SiteElementSerializer).
      to receive(:proxied_url2png).and_return('')
    allow_any_instance_of(ApplicationController).
      to receive(:get_ab_variation).
      with("Sign Up Button 2016-03-17").
      and_return('original')
  end

  scenario "through oauth" do
    OmniAuth.config.add_mock(:google_oauth2, {uid: '12345', info: {email: 'bob@lawblog.com'}})
    visit root_path

    fill_in 'site[url]', with: 'mewgle.com'
    click_button 'sign-up-button'

    expect(page).to have_content('Sign Out', visible: true)
    expect(page).to have_content('Use your Hello Bar to collect visitors', visible: true)
  end
end

feature "User can sign in", js: true do
  after { devise_reset }
  before do
    allow_any_instance_of(ApplicationController).
      to receive(:get_ab_variation).
      with(any_args).
      and_return('original')
  end

  scenario "through email and password" do
    user = create(:user)
    site = user.sites.create(url: random_uniq_url)

    visit new_user_session_path

    fill_in 'Your Email', with: user.email
    click_button 'Continue'

    fill_in 'Password', with: user.password
    click_button 'Continue'

    expect(page).to have_content("SELECT YOUR GOAL")
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

    expect(page).to have_content("SELECT YOUR GOAL")

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  scenario "and sign out" do
    login
    find('.header-user-wrapper .dropdown-wrapper').click
    page.find(:xpath, "//a[@href='/users/sign_out']").click
    expect(page).to have_content('Signed out successfully')
  end

  scenario "user with no sites can sign out" do
    user = login
    user.sites.destroy_all

    visit new_site_path
    find('.header-user-wrapper .dropdown-wrapper').click
    find(:xpath, "//a[@href='/users/sign_out']").click
    expect(page).to have_content('Signed out successfully')
  end
end
