# INTEGRATION
require 'spec_helper'
require 'webmock/rspec'

RSpec.configure do |config|
  config.include Capybara::DSL
  config.include SiteGeneratorHelper
  config.include FeatureHelper

  # Don't override the javascript_driver in a dockerized environment
  Capybara.javascript_driver = :selenium unless ENV['DOCKER']
  OmniAuth.config.test_mode = true

  config.before(:each) do
    allow_any_instance_of(ApplicationController).to receive(:get_ab_variation).and_call_original
    stub_out_get_ab_variations("Targeting UI Variation 2016-06-13") {"original"}
    stub_out_get_ab_variations("Onboarding Limitted To Three Goals 2016-05-11") {"original"}
    stub_out_get_ab_variations("Onboarding Email Volume 2016-06-28") { "original" }

    allow_any_instance_of(SiteSerializer).
      to receive(:monthly_pageviews).and_return(nil)
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

  allow_any_instance_of(ApplicationController).
    to receive(:get_ab_variation).
    with(variation_matcher, anything).
    and_return(result.call)

  allow_any_instance_of(ApplicationController).
    to receive(:get_ab_variation_or_nil).
    with(variation_matcher).
    and_return(result.call)
end
