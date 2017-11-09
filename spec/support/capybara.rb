require 'capybara/rspec'
require 'capybara/rails'
require 'selenium/webdriver'
require 'chromedriver/helper'

# Wait a little longer than the default 2 seconds for Ajax requests to finish
Capybara.default_max_wait_time = 15

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w(headless disable-gpu) }
  )

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    desired_capabilities: capabilities
end

Capybara.javascript_driver = :headless_chrome
Capybara.default_driver = :headless_chrome
