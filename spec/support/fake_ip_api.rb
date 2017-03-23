require 'sinatra/base'
require 'capybara_discoball'

# Define "fake" ip-api.com geolocation service (which sends hardcoded data)
class FakeIPApi < Sinatra::Base
  ip_api_response = {
    as: 'AS6830 Liberty Global Operations B.V.',
    city: 'Gdańsk',
    country: 'Poland',
    countryCode: 'PL',
    isp: 'UPC Polska',
    lat: 54.0000,
    lon: 18.0000,
    org: 'UPC Polska',
    region: 'PM',
    regionName: 'Pomerania',
    status: 'success',
    timezone: 'Europe/Warsaw',
    zip: '80-200'
  }

  get '/*' do
    # CORS headers to allow cross-origin access
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin'

    ip_api_response.to_json
  end
end
