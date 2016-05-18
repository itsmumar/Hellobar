# INTEGRATION
require 'spec_helper'

RSpec.configure do |config|
  config.include Capybara::DSL
  config.include SiteGeneratorHelper
  config.include FeatureHelper

  # Don't override the javascript_driver in a dockerized environment
  Capybara.javascript_driver = :selenium unless ENV['DOCKER']
  OmniAuth.config.test_mode = true

  config.before(:each) do
    # allow us to register which get_ab_variation calls we stubbing,
    # let the rest of the calls pass through to ApplicationController untouched
    allow_any_instance_of(ApplicationController).to receive(:get_ab_variation).and_call_original

    stub_out_get_ab_variations("Forced Email Path 2016-03-28") {"original"}
    stub_out_get_ab_variations("WordPress Plugin 2016-03-17") {"original"}
  end

  config.before(:all) do
    setup_site_generator
  end

  config.before(:suite) do
    begin
      DatabaseCleaner.start
      FactoryGirl.lint

      Rake.application.rake_require "tasks/onboarding_campaigns"
      Rake::Task.define_task(:environment)
    ensure
      DatabaseCleaner.clean
    end
  end
end

def stub_out_get_ab_variations(*variations, &result)
  variation_matcher = Regexp.new(variations.join("|"))

  allow_any_instance_of(ApplicationController).
    to receive(:get_ab_variation).
    with(variation_matcher).
    and_return(result.call)
end
