source 'https://rubygems.org'

gem 'abanalyzer'
gem 'activemerchant',            '~> 1.44.1'
gem 'active_campaign',           '~> 0.1.14'
gem 'active_hash'
gem 'active_link_to', '~> 1.0.2'
gem 'active_model_serializers'
gem 'addressable',               '~> 2.3.6', require: 'addressable/uri'
gem 'avatar',                    '~> 0.2.0'
gem 'aweber',                    '~> 1.6.1'
gem 'aws-sdk',                   '~> 1.66.0'
gem 'bootstrap-sass',            '~> 3.1.1'
gem 'bourbon',                   '~> 3.2.0'
gem 'coffee-rails',              '~> 4.0.0'
gem 'constantcontact',           '~> 1.1.2'
gem 'countries', '0.9.3'
gem 'country_select',            github: 'stefanpenner/country_select', ref: '79755038ca61dafdfebf4c55346d4a2085f98479'
gem 'createsend',                '~> 3.4.0'
gem 'cssmin',                    '~> 1.0.3'
gem 'dalli',                     '~> 2.7.2'
gem 'devise',                    '~> 3.2.4'
gem 'drip-ruby',                 '~> 0.0.10', require: 'drip'
gem 'elif',                      '~> 0.1'
gem 'figaro',                    '~> 1.0.0'
gem 'fog',                       '~> 1.22.1'
gem 'fontcustom',                '~> 1.3.8'
gem 'gibbon',                    '~> 2.2.4'
gem 'google-api-client',         '0.9.8'
gem 'hashie',                    '~> 2.1.1'
gem 'infusionsoft',              '~> 1.1.9'
gem 'jquery-rails',              '~> 3.1.0'
gem 'jwt',                       '~> 1.5.0'
gem 'kaminari',                  '~> 0.15.1'
gem 'less_interactions',         '0.0.15'
gem 'logglier'
gem 'madmimi'
gem 'mini_racer'
gem 'mustache',                  '~> 0.99.5'
gem 'mysql2',                    '~> 0.3.18'
gem 'nokogiri',                  '~> 1.6.7'
gem 'omniauth',                  '~> 1.0'
gem 'omniauth-aweber',           '~> 1.0'
gem 'omniauth-constantcontact2', '~> 1.0'
gem 'omniauth-createsend',       '~> 1.0'
gem 'omniauth-google-oauth2',    '~> 0.2.6'
gem 'omniauth-mailchimp',        github: 'floomoon/omniauth-mailchimp', ref: '239e08d3297cf637b5b0b77b419fdc8461239378'
gem 'omniauth-verticalresponse', '~> 1.0.0'
gem 'paperclip',                 '~> 4.3'
gem 'paranoia',                  '~> 2.0'
gem 'php-serialize',                         require: 'php_serialize'
gem 'phpass-ruby',                           require: 'phpass'
gem 'pony',                      '~> 1.8'
gem 'psych',                     '~> 2.0.5'
gem 'public_suffix',             '~> 1.5.1'
gem 'rack-ssl-enforcer',         '~> 0.2.8'
gem 'rails',                     '4.1.5'

# Be very careful with upgrading rake as version 11 changes the way passing
# param works and double dashes in queue_worker no longer work
gem 'rake', '10.3.2'

gem 'rake_running',              github: 'colinyoung/rake_running', ref: '12d47fe692ffb8cc4112ec25c6b0a9595123c3c3'
gem 'rb-readline',               '~> 0.5.1'
gem 'recaptcha',                 '~> 0.3.6', require: 'recaptcha/rails'
gem 'render_anywhere',           '~> 0.0.9'
gem 'roadie-rails'
gem 'ruby-hmac'
gem 'rubyzip', '>= 1.0.0' # will load new rubyzip version
gem 'sassc-rails',               '~> 1.3'
gem 'sentry-raven',              '~> 0.9'
gem 'signet',                    '~> 0.7.0'
gem 'simple_form',               '3.1.0.rc1'
gem 'slim-rails',                '~> 2.1.4'
gem 'sprockets',                 '~> 3.7.1'
gem 'sprockets-es6'
gem 'thin',                      '~> 1.6.4'
gem 'thread',                    '~> 0.2.2'
gem 'uglifier',                  '~> 3.1'
gem 'unf',                       '~> 0.1.4'
gem 'verticalresponse',          '~> 0.1.6'
gem 'whenever',                  '~> 0.9.2'
# gem "yui-compressor"
gem 'rails-html-sanitizer'
gem 'tzinfo-data', platforms: [:mingw, :mswin] # fixing tzinfo-related bug on Windows platform
gem 'zip-zip' # will load compatibility for old rubyzip API.

gem 'rotp'
gem 'rqrcode'

gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

# Handlebars templates in Rails assets pipeline (js modals)
gem 'handlebars_assets'

group :development do
  gem 'better_errors', '~> 1.1'
  gem 'binding_of_caller'
  gem 'brakeman', require: false
  gem 'hound-tools', '~> 0.0.4', require: false
  gem 'rubocop', require: false

  # Deployment
  gem 'capistrano',                '~> 3.6.1'
  gem 'capistrano-bundler',        '~> 1.1.2'
  gem 'capistrano-rails',          '~> 1.2'
  gem 'slackistrano'
end

group :development, :test do
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'factory_girl_rails'
  gem 'metric_fu'
  gem 'minitest'
  gem 'phantomjs'
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-nav'
  gem 'rspec-rails', '~> 2.99'
  gem 'selenium-webdriver', '~> 2.53.4' # Ubuntu firefox compatible version: 47.0.1
  gem 'simplecov', '~> 0.7.1'
  gem 'sinatra'
  gem 'teaspoon-jasmine'

  # Spring preloader
  gem 'spring'
  gem 'spring-commands-rspec'
end

group :test do
  # Fake ip-api.com server for specs (Geolocation)
  gem 'capybara_discoball'

  # Spec formatters
  gem 'fivemat'
  gem 'rspec_junit_formatter'

  gem 'database_cleaner', '~> 1.5'
  gem 'rspec-retry'
  gem 'shoulda-matchers'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end
