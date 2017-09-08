require 'integration_helper'

feature 'Geolocation', :js do
  given!(:site_element) { create :site_element, :bar, :geolocation }
  given(:site) { site_element.site }
  given!(:subscription) { create :subscription, :pro_managed, site: site }

  scenario 'injection functionality' do
    # Spin up the Rack app
    Capybara::Discoball.spin(FakeIPApi) do |server|
      # update the geolocation_url to the Sinatra server
      allow(Settings).to receive(:geolocation_url).and_return server.url

      visit test_site_path(id: site.id)

      within_frame('random-container-0') do
        expect(page).to have_content 'Country: Poland'
        expect(page).to have_content 'City: Gdańsk'
      end
    end
  end
end
