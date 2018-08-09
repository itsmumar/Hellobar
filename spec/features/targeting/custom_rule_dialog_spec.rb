feature 'Targeting. Custom rule dialog', :js do
  given(:user) { create(:user) }
  given(:site) { create(:site, :with_rule, user: user) }
  given!(:subscription) { create :subscription, :pro, :paid, site: site }

  before do
    sign_in user
  end

  scenario 'cancel button should close dialog' do
    visit new_site_site_element_path(site)

    find('.goal-block.contacts').click

    find('.goal-block.contacts').click
    go_to_tab 'Targeting'
    find('a', text: 'Create new customer targeting rule').click

    expect(page.all('.show-modal.rules-modal').count).to be 1

    sleep 1
    click_on 'Cancel'
    page.has_no_selector?('.cancel.button')
    expect(page.all('.show-modal.rules-modal').count).to be 0
  end
end
