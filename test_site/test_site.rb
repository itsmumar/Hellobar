require 'sinatra'

# run `rake test_site:run` to run this file & navigate to localhost:4567
get '/' do
  "Go to <a href='test.html'>test.html</a>" +
    "<br>Run `rake test_site:generate` to create test.html for last site" +
    "<br>Alternately, pass the site id: `rake test_site:generate[SITE_ID]`"
end
