require 'teaspoon/driver/selenium'
require 'selenium-webdriver'

module Teaspoon
  module Driver
    class ChromeHeadless < Selenium
      def run_specs(runner, url)
        driver = build_driver
        driver.navigate.to(url)
        ::Selenium::WebDriver::Wait.new(driver_options).until do
          done = driver.execute_script('return window.Teaspoon && window.Teaspoon.finished')
          driver.execute_script('return window.Teaspoon && window.Teaspoon.getMessages() || []').each do |line|
            runner.process("#{ line }\n")
          end
          done
        end
      ensure
        driver&.quit
      end

      def build_driver
        capabilities = ::Selenium::WebDriver::Remote::Capabilities.chrome(
          chromeOptions: { args: %w[headless disable-gpu no-sandbox window-size=1920,1080] }
        )

        ::Selenium::WebDriver::Chrome::Driver.new(desired_capabilities: capabilities)
      end
    end
  end
end

Teaspoon::Driver.register(:chrome_headless, 'Teaspoon::Driver::ChromeHeadless', __FILE__)
