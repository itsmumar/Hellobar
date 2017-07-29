ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../support/simplecov', __FILE__)
require File.expand_path('../../config/environment', __FILE__)

# Prevent database truncation if the environment is production/staging/edge
abort("The Rails environment is running in #{ Rails.env } mode!") if Rails.env.production? || Rails.env.staging? || Rails.env.edge?

require 'spec_helper'
require 'rspec/rails'
require 'paperclip/matchers'
require 'email_spec'
require 'email_spec/rspec'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each(&method(:require))
Dir[Rails.root.join('spec', 'models', 'concerns', '**', '*.rb')].each(&method(:require))
Dir[Rails.root.join('spec', 'models', 'validators', '**', '*.rb')].each(&method(:require))

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

ActiveMerchant::Billing::Base.mode = :test

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
end
