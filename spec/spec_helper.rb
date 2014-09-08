# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'simplecov'
require 'metric_fu/metrics/rcov/simplecov_formatter'
require 'database_cleaner'

Zonebie.set_random_timezone

# All metrics should be in the same dir. YOU MADE ME DO THIS, METRIC_FU!
SimpleCov::Formatter::MetricFu.send(:define_method, :coverage_file_path) do
  File.join(SimpleCov.root, 'tmp', 'metric_fu', 'coverage', output_file_name)
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::MetricFu
]

SimpleCov.coverage_dir('tmp/metric_fu/coverage/')

SimpleCov.start

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/models/concerns/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/models/validators/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

VCR.configure do |c|
  c.ignore_localhost = true
  c.cassette_library_dir = "spec/cassettes"
  c.hook_into :webmock
  c.default_cassette_options = {:record => :none} # *TEMPORARILY* set to :new_episodes if you add a spec that makes a network request
end

RSpec.configure do |config|
  # ## VCR
  config.around(:each) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")

    VCR.use_cassette(name) do
      example.run
    end
  end

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.include Devise::TestHelpers, type: :controller
  config.include EmbedCodeFileHelper
end

def stub_current_admin(admin)
  controller.stub :current_admin => admin
end

def stub_current_user(user)
  request.env['warden'].stub :authenticate! => user
  controller.stub :current_user => user

  return user
end

Hellobar::Settings[:host] = "http://hellobar.com"
Hellobar::Settings[:store_site_scripts_locally] = false
Hellobar::Settings[:fake_data_api] = false

Fog.mock!
