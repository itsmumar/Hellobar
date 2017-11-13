require 'integration_helper'

feature 'Site with a closable slider', :js do
  given(:site_element) { create :slider, :closable }

  scenario 'shows headline and allows the bar to be hidden and shown again' do
    visit test_site_path(id: site_element.site.id)

    expect(page).to have_selector '#random-container'
    expect(page).to have_selector 'iframe.hb-animateIn'

    within_frame 'random-container-0' do
      expect(page).to have_content site_element.headline

      expect(page).to have_selector '.icon-close'

      # hide the slider
      find('.icon-close').click
    end

    # HACK: switch to parent frame
    page.find('body').click

    # iframe is hidden
    expect(page).to have_selector '#random-container', visible: false
    expect(page).to have_selector 'iframe.hb-animateOut'
    expect(page).to have_selector '#pull-down .hellobar-arrow'

    # show the slider again
    find('#pull-down .hellobar-arrow').click

    expect(page).to have_selector '#random-container'
    expect(page).to have_selector 'iframe.hb-animateIn'
  end
end
