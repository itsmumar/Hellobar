# INTEGRATION
require 'webmock/rspec'
require 'support/ab_test_config'

SimpleCov.command_name 'test:features' if ENV['COVERAGE'] || ENV['CI']

Dir[Rails.root.join('spec', 'features', 'support', '**', '*.rb')].each(&method(:require))

RSpec.configure do |config|
  config.include SiteGeneratorHelper
  config.include FeatureHelper

  OmniAuth.config.test_mode = true

  config.before(:all) do
    setup_site_generator
  end

  config.include ContactListFeatureHelper, :contact_list_feature

  config.before contact_list_feature: true do
    stub_out_ab_variations('Upgrade Pop-up for Active Users 2016-08') { 'variant' }
    allow(Settings).to receive(:fake_data_api).and_return true
    allow_any_instance_of(FetchContacts).to receive(:call).and_return([])
    allow(FetchContactListTotals).to receive(:new).with(instance_of(Site), id: instance_of(String)).and_return(double(call: 0))
    allow(FetchContactListTotals).to receive(:new).with(instance_of(Site)).and_return(double(call: {}))

    allow(ServiceProvider).to receive(:adapter).and_wrap_original do |original_method, key|
      original_provider = original_method.call(key)
      TestProvider.config = original_provider.config
      TestProvider
    end
  end

  config.before type: :feature do
    allow_any_instance_of(FetchSiteStatistics).to receive(:call).and_return(SiteStatistics.new)
  end
end
