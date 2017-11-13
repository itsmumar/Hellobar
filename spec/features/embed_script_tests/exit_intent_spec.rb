require 'integration_helper'

feature 'element with exit intent', js: true do
  let(:element) { create(:site_element, view_condition: 'exit-intent') }

  scenario 'shows when document is blurred' do
    visit test_site_path(id: element.site.id)

    # iframe should not be showing yet
    page.has_selector?('#random-container')
    expect(page).to have_selector('#random-container', visible: false)

    # trigger blur event
    page.execute_script 'window.onblur && window.onblur()'
    expect(page).to have_selector('#random-container', visible: true)
  end

  scenario 'shows when mouseenter and mouseleave have been triggered' do
    visit test_site_path(id: element.site.id)

    # iframe should not be showing yet
    page.has_selector?('#random-container')
    expect(page).to have_selector('#random-container', visible: false)

    # mouse enter then wait a sufficient amount of time then mouse exit
    page.find('body').hover
    sleep(2.5)
    mouseleave
    expect(page).to have_selector('#random-container', visible: true)
  end
end
