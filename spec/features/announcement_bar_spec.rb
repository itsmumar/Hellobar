require 'integration_helper'

feature "Site with an announcement bar", js: true do
  scenario "shows headline" do
    element = FactoryGirl.create(:site_element)
    path = generate_file_and_return_path(element.site.id)

    visit "#{site_path_to_url(path)}"

    within_frame 'hellobar-container' do
      expect(page).to have_content(element.headline)
    end
  end
end
