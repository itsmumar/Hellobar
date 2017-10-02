require 'integration_helper'

feature 'Alert bar injection', :js do
  given!(:site_element) { create :alert, :traffic }
  given(:site) { site_element.site }
  given!(:subscription) { create :subscription, :pro_managed, site: site }
  given(:last_alert) { Alert.last }

  before do
    expect(GenerateStaticScriptModules).to receive_service_call
  end

  scenario 'injection functionality' do
    visit test_site_path(id: site.id)

    within_frame(find('#random-container')) do
      expect(page).to have_selector '#hellobar-alert.element'
      within '#hellobar-alert.element' do
        expect(page).to have_selector 'audio[src="https://assets.hellobar.com/bell/ring2.mp3"]'
        expect(page).to have_selector '#hb-trigger'
        find('#hb-trigger').click
        expect(page).to have_selector '#hb-popup-container'
        expect(find('#hb-popup-container')).to have_content last_alert.headline
        expect(find('#hb-popup-container')).to have_content last_alert.link_text
      end
    end
  end
end
