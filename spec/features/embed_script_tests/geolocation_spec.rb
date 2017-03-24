require 'integration_helper'

feature 'Geolocation', :js do
  given!(:site_element) { create :site_element, :bar, :geolocation }
  given(:site) { site_element.site }
  given(:path) { generate_file_and_return_path site.id }
  given(:site_path) { site_path_to_url path }
  given!(:subscription) { create :subscription, :pro_managed, site: site }

  before do
    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return 'random'
  end

  scenario 'injection functionality' do
    # Spin up the Rack app
    Capybara::Discoball.spin(FakeIPApi) do |server|
      # update the geolocation_url to the Sinatra server
      Hellobar::Settings[:geolocation_url] = server.url

      visit site_path

      within_frame('random-container-0') do
        expect(page).to have_content 'Country: Poland'
        expect(page).to have_content 'City: Gdańsk'
      end
    end
  end
end
