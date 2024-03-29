feature 'Autofills management', :js do
  given(:user) { create :user, :with_site, email: 'seth@hellobar.com' }
  given(:site) { user.sites.first }
  given!(:subscription) { create :subscription, :pro_managed, site: site }

  given(:name) { 'Email rule' }
  given(:listen_selector) { 'input.email' }
  given(:populate_selector) { 'input.email' }

  given(:new_name) { 'New Email rule' }

  before do
    login_as user, scope: :user, run_callbacks: false
  end

  scenario 'Adding, listing, editing and destroying an autofill' do
    visit site_path site

    click_on 'Autofills'

    expect(page).to have_content 'Autofill Rules'

    click_on 'New Autofill Rule'

    expect(page).to have_content 'new autofill'

    within '.form-inputs' do
      fill_in 'autofill_name', with: name
      fill_in 'autofill_listen_selector', with: listen_selector
      fill_in 'autofill_populate_selector', with: populate_selector
    end

    click_on 'Create Autofill'

    within '.autofills' do
      expect(page).to have_content name
      expect(page).to have_content listen_selector
      expect(page).to have_content populate_selector

      click_on 'Edit'
    end

    expect(page). to have_content 'Edit autofill'

    within '.form-inputs' do
      fill_in 'autofill_name', with: new_name
    end

    click_on 'Update Autofill'

    within '.autofills' do
      expect(page).to have_content new_name
      expect(page).to have_content listen_selector
      expect(page).to have_content populate_selector

      accept_alert do
        click_on 'Destroy'
      end
    end

    expect(page).not_to have_content new_name
    expect(page).not_to have_content listen_selector
    expect(page).not_to have_content populate_selector
  end
end
