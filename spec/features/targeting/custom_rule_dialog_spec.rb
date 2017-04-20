require 'integration_helper'

feature 'Targeting. Custom rule dialog', :js do
  given(:user) { create(:user) }
  given(:site) { create(:site, :with_rule, :pro, user: user) }

  given!(:fake_data_api_original) { Hellobar::Settings[:fake_data_api] }

  before do
    Hellobar::Settings[:fake_data_api] = true
    login user
  end

  after do
    Hellobar::Settings[:fake_data_api] = fake_data_api_original
  end

  scenario 'cancel button should close dialog' do
    visit new_site_site_element_path(site)

    within '.goal-block.contacts' do
      click_on 'Select This Goal'
    end
    click_on 'Continue'
    click_on 'Targeting'
    find('.change-selection').click
    click_on 'Custom Rule'

    expect(page.all('.show-modal.rules-modal').count).to be 1
    click_on 'Cancel'
    expect(page.all('.show-modal.rules-modal').count).to be 0
  end
end
