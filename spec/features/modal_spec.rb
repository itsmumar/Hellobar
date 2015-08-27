require 'integration_helper'

feature "Site with a modal", js: true do
  scenario "removes iframe when modal is closed" do
    element = FactoryGirl.create(:modal_element)
    path = generate_file_and_return_path(element.site.id)

    visit "#{site_path_to_url(path)}"

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="hellobar-container"]')

    page.driver.browser.frame_focus("hellobar-container")
    page.has_selector?('a.icon-close')
    find("a.icon-close").click

    # force capybara to wait until iframe is removed
    page.has_no_selector?("#hellobar-container")
    expect(page).to_not have_xpath('.//iframe[@id="hellobar-container"]')
  end
end
