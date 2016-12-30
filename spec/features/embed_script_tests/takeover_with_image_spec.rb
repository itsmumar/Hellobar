require 'integration_helper'

feature "Takeover with image", js: true do
  scenario "shows the image" do
    element = FactoryGirl.create(:takeover_element, image_placement: 'bottom')
    image = create(:image_upload, :with_valid_image, site: element.site)
    element.update(active_image: image)

    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return('random')
    path = generate_file_and_return_path(element.site.id)

    visit "#{site_path_to_url(path)}"

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    within_frame 'random-container-0' do
      expect(page.find('.uploaded-image')['src']).to have_content(element.image_url)
    end
  end
end
