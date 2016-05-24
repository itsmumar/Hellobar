require 'integration_helper'

feature "Onboarding limitted to three goals ab test", js: true do
  before do
    stub_out_get_ab_variations("Forced Email Path 2016-03-28") {"original"}
    stub_out_get_ab_variations("Onboarding Limitted To Three Goals 2016-05-11") {"variant"}
    user = create(:user)
    @site = user.sites.create(url: random_uniq_url)
    visit new_user_session_path
    fill_in 'Your Email', with: user.email
    click_button 'Continue'
    fill_in 'Password', with: user.password
  end
  after { devise_reset }

  scenario "user created after ab test start date with a variant ab test" do
    allow_any_instance_of(User).to receive(:created_after_limitted_goals_ab_test_start_date).and_return(true)
    click_button 'Continue'
    visit new_site_site_element_path(@site)
    expect(page).not_to have_content("Talk to Your Visitors")
    expect(page).not_to have_content("Get Facebook Likes")
  end

  scenario "user created before ab test start date with a variant ab test" do
    allow_any_instance_of(User).to receive(:created_after_limitted_goals_ab_test_start_date).and_return(false)
    click_button 'Continue'
    visit new_site_site_element_path(@site)
    expect(page).to have_content("Talk to Your Visitors")
    expect(page).to have_content("Get Facebook Likes")
  end
end
