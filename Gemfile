source 'https://rubygems.org'

gem 'abanalyzer'
gem 'activemerchant', '~> 1.44.1'
gem 'active_campaign', '~> 0.1.14'
gem 'active_hash'
gem 'active_link_to'
gem 'active_model_serializers'
gem 'addressable', require: 'addressable/uri'
gem 'avatar'
gem 'aweber'
gem 'aws-sdk'
gem 'bootstrap-sass', '~> 3.1.1'
gem 'bourbon', '~> 3.2.0'
gem 'coffee-rails'
gem 'constantcontact'
gem 'countries'
gem 'country_select', github: 'stefanpenner/country_select', ref: '79755038ca61dafdfebf4c55346d4a2085f98479'
gem 'createsend'
gem 'dalli'
gem 'devise'
gem 'drip-ruby', require: 'drip'
gem 'elif'
gem 'figaro'
gem 'fog-aws'
gem 'fontcustom'
gem 'gibbon'
gem 'google-api-client'
gem 'hashie'
gem 'infusionsoft'
gem 'jquery-rails'
gem 'jwt'
gem 'kaminari'
gem 'less_interactions'
gem 'logglier'
gem 'madmimi'
gem 'mini_racer'
gem 'mustache'
gem 'mysql2', '~> 0.3.18'
gem 'nokogiri'
gem 'oj'
gem 'oj_mimic_json'
gem 'omniauth', '~> 1.0'
gem 'omniauth-aweber', '~> 1.0'
gem 'omniauth-constantcontact2', '~> 1.0'
gem 'omniauth-createsend', '~> 1.0'
gem 'omniauth-google-oauth2', '~> 0.2.6'
gem 'omniauth-mailchimp', github: 'floomoon/omniauth-mailchimp', ref: '239e08d3297cf637b5b0b77b419fdc8461239378'
gem 'omniauth-verticalresponse', '~> 1.0.0'
gem 'paperclip'
gem 'paranoia'
gem 'php-serialize', require: 'php_serialize'
gem 'phpass-ruby', require: 'phpass'
gem 'pony'
gem 'psych'
gem 'public_suffix'
gem 'rack-ssl-enforcer'
gem 'rails', '~> 4.1.16'

# Be very careful with upgrading rake as version 11 changes the way passing
# param works and double dashes in queue_worker no longer work
gem 'rake', '~> 10.3.2'

gem 'rake_running', github: 'colinyoung/rake_running', ref: '12d47fe692ffb8cc4112ec25c6b0a9595123c3c3'
gem 'recaptcha', require: 'recaptcha/rails'
gem 'render_anywhere'
gem 'roadie-rails'
gem 'ruby-hmac'
gem 'rubyzip'
gem 'sassc-rails'
gem 'sentry-raven'
gem 'signet'
gem 'simple_form'
gem 'slim-rails'
gem 'sprockets'
gem 'sprockets-es6'
gem 'thin', '~> 1.6.4'
gem 'thread'
gem 'uglifier'
gem 'unf'
gem 'verticalresponse'
gem 'whenever'
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
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'brakeman', require: false
  gem 'hound-tools', require: false
  gem 'rubocop', require: false

  # Deployment
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'slackistrano'
end

group :development, :test do
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'factory_girl_rails'
  gem 'phantomjs'
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-nav'
  gem 'rspec-rails', '~> 3.5'
  gem 'simplecov'
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
  gem 'rspec_junit_formatter'

  gem 'database_cleaner'
  gem 'rspec-retry'
  gem 'shoulda-matchers'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end
