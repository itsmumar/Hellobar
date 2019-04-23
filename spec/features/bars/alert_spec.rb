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

    find('.goal-block.contacts').click

    find('.goal-block.contacts').click

    find('a', text: 'Publish Now').click
    expect(page).to have_content('Summary')
  end
end
