# INTEGRATION
require 'spec_helper'

RSpec.configure do |config|
  config.include Capybara::DSL
  config.include SiteGeneratorHelper

  Capybara.javascript_driver = :webkit

  config.before(:all) do
    setup_site_generator
  end

  config.after(:all) do
    teardown_site_generator
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
