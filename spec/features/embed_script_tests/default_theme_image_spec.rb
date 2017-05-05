require 'integration_helper'

feature 'Theme with default image', js: true do
  scenario 'shows the default image' do
    theme_yaml = YAML.load_file('spec/support/themes.yml')
    theme = Theme.new(theme_yaml['with_default_image'])
    image = ImageUpload.create(
      theme_id: theme.id,
      preuploaded_url: theme.image['default_url'],
      image_file_name: 'french-rose-default.jpg'
    )
    element = create :modal_element, theme_id: theme.id, use_default_image: true
    element.update(active_image: image)

    allow_any_instance_of(StaticScriptModel).to receive(:pro_secret).and_return('random')
    path = generate_file_and_return_path(element.site.id)

    visit site_path_to_url(path)

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    within_frame 'random-container-0' do
      expect(page.find('.uploaded-image')['src']).to have_content(element.image_url)
    end
  end

  scenario 'shows uploaded image' do
    theme_yaml = YAML.load_file('spec/support/themes.yml')
    theme = Theme.new(theme_yaml['with_default_image'])
    element = create(
      :modal_element,
      image_placement: 'bottom',
      theme_id: theme.id,
      use_default_image: false
    )
    image = create(:image_upload, :with_valid_image, site: element.site)
    element.update(active_image: image)

    allow_any_instance_of(StaticScriptModel).to receive(:pro_secret).and_return('random')
    path = generate_file_and_return_path(element.site.id)

    visit site_path_to_url(path)

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    within_frame 'random-container-0' do
      expect(page.find('.uploaded-image')['src']).to have_content(element.image_url)
    end
  end
end
