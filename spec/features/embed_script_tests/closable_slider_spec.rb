require 'integration_helper'

feature 'Site with a closable slider', :js do
  given(:site_element) { create :site_element, :slider, :closable }
  given(:path) { generate_file_and_return_path(site_element.site.id) }

  before do
    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return('random')
  end

  scenario 'shows headline and allows the bar to be hidden and shown again' do
    visit  site_path_to_url(path).to_s

    # force capybara to wait until iframe is loaded
    expect(page).to have_selector '#random-container'

    within_frame 'random-container-0' do
      expect(page).to have_content site_element.headline

      expect(page).to have_selector '.icon-close'

      # hide the slider
      find('.icon-close').trigger 'click'
    end

    expect(page).to have_selector '#random-container', visible: false

    # show the slider again
    find('#pull-down').trigger 'click'

    expect(page).to have_selector '#random-container'
  end
end
