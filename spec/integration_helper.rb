# INTEGRATION
require 'spec_helper'

RSpec.configure do |config|
  config.include Capybara::DSL
  config.include SiteGeneratorHelper
  config.include FeatureHelper

  Capybara.javascript_driver = :selenium
  OmniAuth.config.test_mode = true

  config.before(:all) do
    setup_site_generator
  end

  config.before(:suite) do
    begin
      DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
  end
end
