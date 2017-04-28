require 'sinatra'

# Run `rake test_site:generate` to create test.html for last site
# Alternately, pass the site id: `rake test_site:generate[SITE_ID]`
# Run `rake test_site:run` to run this file & navigate to localhost:4567

# Bind Sinatra app to an actual network interface
# This allows you to expose your IP on the router and access your local Sinatra
# app from the internet
set :bind, '0.0.0.0'

# Explicitly set Sintatra's public folder so that image uploads are served
# and displayed in bars
set :public_folder, 'public/'

# Route all traffic to test_site.html
get '*' do
  File.read('public/test_site.html')
end
