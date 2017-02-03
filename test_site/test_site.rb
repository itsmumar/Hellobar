require 'sinatra'

# Run `rake test_site:generate` to create test.html for last site
# Alternately, pass the site id: `rake test_site:generate[SITE_ID]`
# Run `rake test_site:run` to run this file & navigate to localhost:4567

# Bind Sinatra app to an actual network interface
# This allows you to expose your IP on the router and access your local Sinatra
# app from the internet
set :bind, '0.0.0.0'

get '*' do
  File.read('test_site/public/test.html')
end
