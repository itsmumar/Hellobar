require 'sinatra'

# Run `rake test_site:generate` to create test.html for last site
# Alternately, pass the site id: `rake test_site:generate[SITE_ID]`
# Run `rake test_site:run` to run this file & navigate to localhost:4567
get '/' do
  File.read('test_site/public/test.html')
end
