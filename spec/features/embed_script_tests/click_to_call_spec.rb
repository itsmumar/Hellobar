require 'integration_helper'

feature 'Visit click to call on desktop browser', js: true do
  scenario "doesn't show the site element" do
    element = create(:modal, element_subtype: 'call', phone_number: '(555)-555-5555')

    visit test_site_path(id: element.site.id)

    expect(page).not_to have_xpath('.//iframe[@id="random-container"]')
  end
end

feature 'Visit click to call on mobile browser', js: true do
  scenario 'shows the click to call site element' do
    element = create(:modal, element_subtype: 'call', phone_number: '(555)-555-5555')

    Capybara.current_session.driver.header('User-Agent', 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1')

    visit test_site_path(id: element.site.id)

    expect(page).to have_xpath('.//iframe[@id="random-container"]')
  end
end
