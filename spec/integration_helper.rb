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
    allow_any_instance_of(FetchAllContacts).to receive(:call).and_return([])
    allow_any_instance_of(FetchLatestContacts).to receive(:call).and_return([])

    allow(FetchSiteContactListTotals).to receive(:new).with(instance_of(Site), instance_of(Array)).and_return(double(call: Hash.new { 0 }))
    allow(FetchSiteContactListTotals).to receive(:new).with(instance_of(Site)).and_return(double(call: Hash.new { 0 }))

    OmniAuth.config.add_mock(provider)
  end

  config.before type: :feature do
    allow_any_instance_of(FetchSiteStatistics).to receive(:call).and_return(SiteStatistics.new)
  end

  config.before :suite do
    # precompile static script assets
    begin
      StaticScriptAssets.digest_path('modules.js')
    rescue Sprockets::FileNotFound
      puts 'precompiling static script assets...'
      StaticScriptAssets.precompile
      puts 'finished precompiling static script assets'
    end

    # precompile modules.js separately (if they don't exist)
    path = Rails.root.join('public', 'generated_scripts', StaticScriptAssets.digest_path('modules.js'))
    unless File.exist? path
      puts 'precompiling modules.js...'
      GenerateStaticScriptModules.new.call
      puts 'finished precompiling modules.js'
    end
  end
end
