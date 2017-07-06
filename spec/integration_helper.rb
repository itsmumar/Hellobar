# INTEGRATION
require 'webmock/rspec'
require 'support/ab_test_config'

SimpleCov.command_name 'test:features' if ENV['COVERAGE'] || ENV['CI']

Dir[Rails.root.join('spec', 'features', 'support', '**', '*.rb')].each(&method(:require))

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

  config.include ContactListFeatureHelper, :contact_list_feature
  config.before contact_list_feature: true do
    stub_out_ab_variations('Upgrade Pop-up for Active Users 2016-08') { 'variant' }
    allow(Settings).to receive(:fake_data_api).and_return true
    allow(ServiceProvider).to receive(:adapter).and_wrap_original do |original_method, key|
      original_provider = original_method.call(key)
      TestProvider.config = original_provider.config
      TestProvider
    end
  end
end
