# INTEGRATION
require 'rails_helper'
require 'webmock/rspec'
require 'support/ab_test_config'

SimpleCov.command_name 'test:features' if ENV['COVERAGE'] || ENV['CI']

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
      FactoryGirl.lint

      Rake.application.rake_require 'tasks/onboarding_campaigns'
      Rake::Task.define_task(:environment)
    ensure
      DatabaseCleaner.clean
    end
  end
end
