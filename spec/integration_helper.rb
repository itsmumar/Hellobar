# INTEGRATION
require 'webmock/rspec'
require 'support/ab_test_config'

SimpleCov.command_name 'test:features' if ENV['COVERAGE'] || ENV['CI']

RSpec.configure do |config|
  config.include FeatureHelper

  OmniAuth.config.test_mode = true

  config.include ContactListFeatureHelper, :contact_list_feature

  config.before contact_list_feature: true do
    stub_out_ab_variations('Upgrade Pop-up for Active Users 2016-08') { 'variant' }
    allow_any_instance_of(FetchContacts).to receive(:call).and_return([])
    allow(FetchContactListTotals).to receive(:new).with(instance_of(Site), id: instance_of(String)).and_return(double(call: 0))
    allow(FetchContactListTotals).to receive(:new).with(instance_of(Site)).and_return(double(call: {}))

    OmniAuth.config.add_mock(provider)
  end

  config.before type: :feature do
    allow_any_instance_of(FetchSiteStatistics).to receive(:call).and_return(SiteStatistics.new)
  end

  config.before :suite do
    # precompile modules.js if it hasn't been compiled
    begin
      StaticScriptAssets.digest_path('modules.js')
    rescue Sprockets::FileNotFound
      StaticScriptAssets.precompile
      GenerateStaticScriptModules.new.call
    end
  end
end
