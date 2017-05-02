require 'integration_helper'

feature 'element with exit intent', js: true do
  let(:element) { create(:site_element, view_condition: 'exit-intent') }

  before do
    allow_any_instance_of(RenderStaticScript).to receive(:pro_secret).and_return('random')
  end

  scenario 'shows when document is blurred' do
    path = generate_file_and_return_path(element.site.id)

    visit site_path_to_url(path)

    # iframe should not be showing yet
    page.has_selector?('#random-container')
    expect(page).to have_selector('#random-container', visible: false)

    # trigger blur event
    page.find('body').trigger('blur')
    expect(page).to have_selector('#random-container', visible: true)
  end

  scenario 'shows when mouseenter and mouseleave have been triggered' do
    path = generate_file_and_return_path(element.site.id)

    visit site_path_to_url(path)

    # iframe should not be showing yet
    page.has_selector?('#random-container')
    expect(page).to have_selector('#random-container', visible: false)

    # mouse enter then wait a sufficient amount of time then mouse exit
    page.find('body').trigger('mouseenter')
    sleep(2.5)
    page.find('body').trigger('mouseleave')
    expect(page).to have_selector('#random-container', visible: true)
  end
end
