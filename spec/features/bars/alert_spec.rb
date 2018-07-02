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

    within '.goal-block.money' do
      click_on 'Select This Goal'
    end

    click_on 'Continue'
    find('a', text: 'CHANGE TYPE').click
    find('h6', text: 'Alert').click
    first('.autodetection-button').click
    click_button 'Save & Publish'
    click_on 'Manage'

    expect(page).to have_selector '[data-type="alert"]'
  end
end
