require 'capybara/rspec'
require 'capybara/rails'
require 'selenium/webdriver'
require 'mkmf'

MakeMakefile::Logging.instance_variable_set(:@logfile, '/dev/null')
Selenium::WebDriver::Chrome.driver_path = find_executable('chromedriver')

# Wait a little longer than the default 2 seconds for Ajax requests to finish
Capybara.default_max_wait_time = 15

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w[headless disable-gpu no-sandbox window-size=1920,1080] }
  )

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    desired_capabilities: capabilities
end

Capybara.register_driver :mobile_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: {
      args: %w[headless disable-gpu no-sandbox],
      mobileEmulation: {
        userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1',
        deviceMetrics: {
          width: 736,
          height: 414
        }
      }
    }
  )

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    desired_capabilities: capabilities
end

Capybara.javascript_driver = :headless_chrome

RSpec.configure do |config|
  config.before mobile: true do
    Capybara.current_driver = :mobile_chrome
  end

  config.after mobile: true do
    Capybara.use_default_driver
  end
end
