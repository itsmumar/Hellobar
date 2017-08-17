require 'integration_helper'

feature 'Targeting. Custom rule dialog', :js do
  given(:user) { create(:user) }
  given(:site) { create(:site, :with_rule, user: user) }

  before { create :subscription, :pro, :paid, site: site }

  before do
    login user
  end

  scenario 'cancel button should close dialog' do
    visit new_site_site_element_path(site)

    within '.goal-block.contacts' do
      click_on 'Select This Goal'
    end
    click_on 'Continue'
    click_on 'Targeting'
    find('.change-selection').click
    find('h6', text: 'Custom Rule').click

    expect(page.all('.show-modal.rules-modal').count).to be 1
    click_on 'Cancel'
    expect(page.all('.show-modal.rules-modal').count).to be 0
  end
end
