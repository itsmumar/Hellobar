# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'
  SimpleCov.command_name 'test:unit'
  SimpleCov.coverage_dir 'tmp/coverage'
  SimpleCov.start do
    # we test seeds in a different way - just by running them
    add_filter '/lib/seeds/'
  end
end

require File.expand_path('../../config/environment', __FILE__)

abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
require 'paperclip/matchers'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each(&method(:require))
Dir[Rails.root.join('spec', 'models', 'concerns', '**', '*.rb')].each(&method(:require))
Dir[Rails.root.join('spec', 'models', 'validators', '**', '*.rb')].each(&method(:require))

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

VCR.configure do |c|
  c.ignore_localhost = true
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :none } # *TEMPORARILY* set to :new_episodes or :once if you add a spec that makes a network request
end

Fog.mock!

ActiveMerchant::Billing::Base.mode = :test

Hellobar::Settings[:host] = 'localhost'
Hellobar::Settings[:store_site_scripts_locally] = true
Hellobar::Settings[:fake_data_api] = false
Hellobar::Settings[:cybersource_environment] = :test
Hellobar::Settings[:syncable] = true
Hellobar::Settings[:support_location] = 'http://support.hellobar.com/'

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  ### Custom

  config.around(:each) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join('/').underscore.gsub(/[^\w\/]+/, '_')

    VCR.use_cassette(name) do
      example.run
    end
  end

  config.before(:suite) do
    begin
      DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
  end

  config.include Devise::TestHelpers, type: :controller
  config.include EmbedCodeFileHelper
  config.include StubsHelper
  config.include Paperclip::Shoulda::Matchers
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ControllerSpecHelper, type: :controller
end
