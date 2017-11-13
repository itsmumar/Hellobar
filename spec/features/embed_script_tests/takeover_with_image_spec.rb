require 'integration_helper'

feature 'Takeover with image', js: true do
  scenario 'shows large image' do
    element = create(:takeover, image_placement: 'bottom')
    image = create(:image_upload, :with_valid_image, site: element.site)
    element.update(active_image: image)

    visit test_site_path(id: element.site.id)

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    within_frame 'random-container-0' do
      expect(page.find('.uploaded-image', visible: false)['src']).to have_content(element.image_large_url)
    end
  end

  context 'with autodetect theme' do
    scenario 'shows large image' do
      element = create(:takeover, image_placement: 'bottom', theme_id: 'autodetect')
      image = create(:image_upload, :with_valid_image, site: element.site)
      element.update(active_image: image)

      visit test_site_path(id: element.site.id)

      # force capybara to wait until iframe is loaded
      page.has_xpath?('.//iframe[@id="random-container"]')

      within_frame 'random-container-0' do
        expect(page.find('.uploaded-image', visible: false)['src']).to have_content(element.image_large_url)
      end
    end
  end
end
