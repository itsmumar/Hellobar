require 'integration_helper'

feature "Site with a modal", :js do
  let(:site_element) { create(:modal_element) }
  let(:path) { generate_file_and_return_path(site_element.site.id) }

  before do
    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return('random')
  end

  scenario "removes iframe when modal is closed" do
    visit site_path_to_url(path).to_s

    # force capybara to wait until iframe is loaded
    expect(page).to have_selector "#random-container"

    page.driver.browser.frame_focus("random-container-0")

    page.has_selector?('a.icon-close')
    find("a.icon-close").click

    # force capybara to wait until iframe is removed
    page.has_no_selector?("#random-container")
    expect(page).to_not have_xpath('.//iframe[@id="random-container"]')
  end
end
