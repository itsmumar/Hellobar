require 'capybara/rspec'
require 'capybara/rails'
require 'capybara/webkit'

# Use Webkit as js driver
Capybara.javascript_driver = :webkit

Capybara::Webkit.configure do |config|
  config.block_unknown_urls
  config.timeout = 120
  config.skip_image_loading
end

# Wait a little longer than the default 2 seconds for Ajax requests to finish
Capybara.default_max_wait_time = 15
