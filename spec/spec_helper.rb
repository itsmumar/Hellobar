# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'simplecov'
require 'metric_fu/metrics/rcov/simplecov_formatter'
require 'database_cleaner'
require 'paperclip/matchers'

require 'capybara/rspec'
require 'capybara/rails'
require 'capybara/webkit'

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

SimpleCov.start do
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Helpers", "app/helpers"
  add_group "Interactions", "app/interactions"
  add_group "Mailers", "app/mailers"
  add_group "Serializers", "app/serializers"
  add_group "lib", "lib"
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/models/concerns/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/models/validators/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

# un-comment this line to see sql statements in console
# ActiveRecord::Base.logger = Logger.new(STDOUT)

VCR.configure do |c|
  c.ignore_localhost = true
  c.cassette_library_dir = "spec/cassettes"
  c.hook_into :webmock
  c.default_cassette_options = {:record => :none} # *TEMPORARILY* set to :new_episodes if you add a spec that makes a network request
end

# Use Webkit as js driver
Capybara.javascript_driver = :webkit

Capybara::Webkit.configure do |config|
  config.block_unknown_urls
  config.timeout = 60
  config.skip_image_loading
end

# Wait longer than the default 2 seconds for Ajax requests to finish
Capybara.default_max_wait_time = ENV['CI'] ? 30 : 10

RSpec.configure do |config|
  # Use a separate container for selenium
  if ENV['DOCKER']
    require 'selenium-webdriver'

    Capybara.register_driver :remote_firefox do |app|
      Capybara::Selenium::Driver.new(app,
                                     browser: :remote,
                                     url: "http://selenium-firefox:4444/wd/hub",
                                     desired_capabilities: :firefox)
    end

    Capybara.default_driver = :remote_firefox
    Capybara.javascript_driver = :remote_firefox
    Capybara.app_host = "http://web"
    Capybara.run_server = false
  end

  # ## VCR
  config.around(:each) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")

    # Don't run VCR in a dockerized environment
    next if ENV['DOCKER']

    VCR.use_cassette(name) do
      example.run
    end
  end

  config.after(:each) do
    if example.exception && example.metadata[:js]
      meta = example.metadata
      filename = File.basename(meta[:file_path])
      line_number = meta[:line_number]
      screenshot_name = "screenshot-#{filename}-#{line_number}.png"
      screenshot_path = "#{ENV.fetch('CIRCLE_ARTIFACTS', Rails.root.join('tmp/capybara'))}/#{screenshot_name}"

      page.save_screenshot(screenshot_path)

      puts meta[:full_description] + "\n Screenshot: #{screenshot_path}"
    end
  end

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Allow tagging js specs using just symbols
  config.treat_symbols_as_metadata_keys_with_true_values = true

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
  config.include FactoryGirl::Syntax::Methods
  config.include EmbedCodeFileHelper
  config.include Paperclip::Shoulda::Matchers
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ControllerSpecHelper, type: :controller
end

def stub_current_admin(admin)
  controller.stub :current_admin => admin
end

def stub_current_user(user)
  request.env['warden'].stub :authenticate! => user
  controller.stub :current_user => user

  return user
end

def random_uniq_url
  Faker::Internet.url.split(".").insert(1, "-#{(0...8).map{65.+(rand(26)).chr}.join.downcase}").insert(2, ".").join
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

Hellobar::Settings[:host] = "http://hellobar.com"
Hellobar::Settings[:store_site_scripts_locally] = false
Hellobar::Settings[:fake_data_api] = false
Hellobar::Settings[:cybersource_environment] = :test
Hellobar::Settings[:syncable] = true
Hellobar::Settings[:support_location] = "http://support.hellobar.com/"

Fog.mock!

ActiveMerchant::Billing::Base.mode = :test
