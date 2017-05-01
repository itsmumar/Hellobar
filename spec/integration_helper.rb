# INTEGRATION
require 'webmock/rspec'
require 'support/ab_test_config'

SimpleCov.command_name 'test:features' if ENV['COVERAGE'] || ENV['CI']

# Use Webkit as js driver
Capybara.javascript_driver = :webkit
Capybara::Webkit.configure do |config|
  config.block_unknown_urls
  config.timeout = 60
  config.skip_image_loading
end

Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.include SiteGeneratorHelper
  config.include FeatureHelper

  OmniAuth.config.test_mode = true

  config.before(:all) do
    setup_site_generator
  end

  config.before(:suite) do
    begin
      DatabaseCleaner.start
      Rake.application.rake_require 'tasks/onboarding_campaigns'
      Rake::Task.define_task(:environment)
    ensure
      DatabaseCleaner.clean
    end
  end

  config.before(:each) do
    allow_any_instance_of(SettingsSerializer)
      .to receive(:needs_filling_questionnaire?).and_return(false)
  end
end
