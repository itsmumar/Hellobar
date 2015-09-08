require 'integration_helper'

feature "Site with an announcement bar", js: true do
  scenario "shows headline" do
    element = FactoryGirl.create(:site_element)
    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return('random')
    path = generate_file_and_return_path(element.site.id)

    visit "#{site_path_to_url(path)}"

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    within_frame 'random-container' do
      expect(page).to have_content(element.headline)
    end
  end
end
