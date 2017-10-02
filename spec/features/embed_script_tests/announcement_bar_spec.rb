require 'integration_helper'

feature 'Site with a closable announcement topbar', :js do
  given(:element) { create :bar, :closable }

  scenario 'shows headline and allows the bar to be hidden an shown again' do
    visit test_site_path(id: element.site.id)

    # force capybara to wait until iframe is loaded
    expect(page).to have_selector '#random-container'

    within_frame 'random-container-0' do
      expect(page).to have_content element.headline

      expect(page).to have_selector '.icon-close'

      # hide the bar
      find('.icon-close').trigger 'click'
    end

    expect(page).to have_selector '#random-container', visible: false

    # show the bar again
    find('#pull-down').trigger 'click'

    expect(page).to have_selector '#random-container'
  end
end
