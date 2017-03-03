require 'integration_helper'

feature 'Visit click to call on desktop browser', js: true do
  scenario "doesn't show the site element" do
    element = create(:modal_element, element_subtype: 'call', phone_number: '(555)-555-5555')
    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return('random')
    path = generate_file_and_return_path(element.site.id)

    visit site_path_to_url(path).to_s

    expect(page).to_not have_xpath('.//iframe[@id="random-container"]')
  end
end

feature 'Visit click to call on mobile browser', js: true do
  scenario 'shows the click to call site element' do
    element = create(:modal_element, element_subtype: 'call', phone_number: '(555)-555-5555')
    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return('random')
    path = generate_file_and_return_path(element.site.id)

    Capybara.current_session.driver.header('User-Agent', 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1')

    visit site_path_to_url(path).to_s

    expect(page).to have_xpath('.//iframe[@id="random-container"]')
  end
end
