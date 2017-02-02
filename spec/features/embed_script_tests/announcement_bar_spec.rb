require 'integration_helper'

feature 'Site with a closable announcement topbar', :js do
  given(:element) { FactoryGirl.create :site_element, :bar, :closable }
  given(:path) { generate_file_and_return_path(element.site.id) }

  before do
    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return('random')
  end

  scenario 'shows headline and allows the bar to be hidden an shown again' do
    visit "#{ site_path_to_url(path) }"

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    within_frame 'random-container-0' do
      # has headline
      expect(page).to have_content element.headline

      expect(page).to have_selector '.icon-close'

      # hide the bar
      find('.icon-close').trigger 'click'
    end

    # show the bar again
    expect(page).to have_selector '#pull-down'
    find('#pull-down').trigger 'click'

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    within_frame 'random-container-0' do
      # has headline again
      expect(page).to have_content element.headline
    end

    # reload the page and expect the bar to be visible
    visit "#{ site_path_to_url(path) }"

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    within_frame 'random-container-0' do
      expect(page).to have_content element.headline
    end
  end
end
