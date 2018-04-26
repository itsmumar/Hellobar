ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../support/simplecov', __FILE__)
require File.expand_path('../../config/environment', __FILE__)

# Prevent database truncation if the environment is production/staging/edge
abort("The Rails environment is running in #{ Rails.env } mode!") if Rails.env.production? || Rails.env.staging? || Rails.env.edge?

require 'spec_helper'
require 'rspec/rails'
require 'paperclip/matchers'
require 'support/page_object'
require 'webmock/rspec'
require 'support/ab_test_config'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each(&method(:require))
Dir[Rails.root.join('spec', 'models', 'concerns', '**', '*.rb')].each(&method(:require))
Dir[Rails.root.join('spec', 'models', 'validators', '**', '*.rb')].each(&method(:require))

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

ActiveMerchant::Billing::Base.mode = :test

SimpleCov.command_name 'test:features' if ENV['COVERAGE'] || ENV['CI']

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include StubsHelper
  config.include Paperclip::Shoulda::Matchers
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ControllerSpecHelper, type: :controller
  config.include RequestSpecHelper, type: :request
  config.include ServiceProviderHelper, type: :service_provider
  config.include Warden::Test::Helpers
  config.include FeatureHelper
  config.include ContactListFeatureHelper, :contact_list_feature

  OmniAuth.config.test_mode = true

  config.before(:each) do
    Rails.cache.clear
  end

  config.before(type: :request) do
    OmniAuth.config.test_mode = true
  end

  config.after(:each, type: :feature) do
    Warden.test_reset!
  end

  config.before(:each, type: :feature) do
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

  config.before contact_list_feature: true do
    stub_out_ab_variations('Upgrade Pop-up for Active Users 2016-08') { 'variant' }
    allow_any_instance_of(FetchAllContacts).to receive(:call).and_return([])
    allow_any_instance_of(FetchLatestContacts).to receive(:call).and_return([])

    allow(FetchSiteContactListTotals).to receive(:new).with(instance_of(Site), instance_of(Array)).and_return(double(call: Hash.new { 0 }))
    allow(FetchSiteContactListTotals).to receive(:new).with(instance_of(Site)).and_return(double(call: Hash.new { 0 }))

    OmniAuth.config.add_mock(provider)
  end
end
