require 'integration_helper'

feature 'Theme with default image', js: true do
  scenario 'shows the default image' do
    theme_yaml = YAML.load_file('spec/support/themes.yml')
    theme = Theme.new(theme_yaml['with_default_image'])
    element = create :modal, theme_id: theme.id, use_default_image: true

    visit test_site_path(id: element.site.id)

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    within_frame 'random-container-0' do
      expect(page.find('.uploaded-image')['src']).to have_content(theme.image['default_url'])
    end
  end

  scenario 'shows uploaded image' do
    theme_yaml = YAML.load_file('spec/support/themes.yml')
    theme = Theme.new(theme_yaml['with_default_image'])
    element = create(
      :modal,
      image_placement: 'bottom',
      theme_id: theme.id,
      use_default_image: false
    )
    image = create(:image_upload, :with_valid_image, site: element.site)
    element.update(active_image: image)

    visit test_site_path(id: element.site.id)

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    within_frame 'random-container-0' do
      expect(page.find('.uploaded-image')['src']).to have_content(element.image_url)
    end
  end
end
