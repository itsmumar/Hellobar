feature 'Adding Alert bar', :js do
  given(:email) { 'bob@lawblog.com' }
  given(:site) { create :site, :with_user, :with_rule, :pro_managed }
  given(:user) { site.owners.last }

  before do
    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: user.email })

    sign_in user
  end

  scenario 'new user can create an alert bar' do
    visit new_site_site_element_path(site)

    within '.goal-block.other' do
      click_on 'Make Announcment'
    end

    click_on 'Continue'
    go_to_tab 'Type'
    find('h6', text: 'Alert').click
    find('a', text: 'Save & Publish').click
    click_on 'Manage'

    expect(page).to have_selector '[data-type="alert"]'
  end
end
