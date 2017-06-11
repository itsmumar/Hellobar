source 'https://rubygems.org'

gem 'rails', '4.2.8'

# AWS
gem 'aws-sdk'

# Authentication / authorization
gem 'devise'
gem 'google-api-client'
gem 'omniauth'
gem 'signet'

# OTP Authentication (One Time Passwords)
gem 'rotp'
gem 'rqrcode'
gem 'ruby-hmac'

# Email integrations
gem 'active_campaign'
gem 'aweber'
gem 'constantcontact'
gem 'createsend' # CampaignMonitor
gem 'drip-ruby', require: 'drip'
gem 'faraday' # Webhooks adapter
gem 'gibbon' # MailChimp
gem 'infusionsoft'
gem 'madmimi'
gem 'omniauth-aweber'
gem 'omniauth-constantcontact2'
gem 'omniauth-createsend'
gem 'omniauth-google-oauth2'
gem 'omniauth-mailchimp', github: 'floomoon/omniauth-mailchimp', ref: '239e08d3297cf637b5b0b77b419fdc8461239378'
gem 'omniauth-verticalresponse'
gem 'verticalresponse'

# Mailing
gem 'pony'

# Billing
gem 'activemerchant', '~> 1.65.0'

# Assets / Frontend
gem 'active_link_to'
gem 'autoprefixer-rails'
gem 'bootstrap-sass', '~> 3.1.1'
gem 'coffee-rails'
gem 'countries'
gem 'country_select', github: 'stefanpenner/country_select', ref: '79755038ca61dafdfebf4c55346d4a2085f98479'
gem 'handlebars_assets' # Handlebars templates in Rails assets pipeline (js modals)
gem 'jquery-rails'
gem 'jwt'
gem 'mustache'
gem 'rails-html-sanitizer'
gem 'sassc-rails'
gem 'simple_form'
gem 'slim-rails'
gem 'sprockets'
gem 'sprockets-es6'

# ActiveRecord / Database
gem 'kaminari'
gem 'mysql2'

# File uploads
gem 'paperclip', '~> 5.1'

# JSON
gem 'active_model_serializers'
gem 'jbuilder'

# Real-time error reporting
gem 'sentry-raven'

# Web server
gem 'thin', '~> 1.6.4'

# Others
gem 'abanalyzer'
gem 'active_hash'
gem 'addressable', require: 'addressable/uri'
gem 'avatar'
gem 'dalli'
gem 'elif'
gem 'hashie'
gem 'less_interactions'
gem 'nokogiri'
gem 'paranoia'
gem 'php-serialize', require: 'php_serialize'
gem 'phpass-ruby', require: 'phpass'
gem 'psych'
gem 'public_suffix'
gem 'rack-ssl-enforcer'
gem 'rake_running', github: 'colinyoung/rake_running', ref: '12d47fe692ffb8cc4112ec25c6b0a9595123c3c3'
gem 'render_anywhere'
gem 'roadie-rails'
gem 'rubyzip'
gem 'thread'
gem 'uglifier'
gem 'unf'
gem 'whenever'
gem 'zip-zip' # will load compatibility for old rubyzip API.

# Sending analytics data to Segment.com
gem 'analytics-ruby', require: 'segment/analytics'

# Queue
gem 'connection_pool'
gem 'shoryuken'

# Be very careful with upgrading rake as version 11 changes the way passing
# param works and double dashes in queue_worker no longer work
gem 'rake', '~> 10.3.2'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'

  # Static code analysis
  gem 'brakeman', require: false
  gem 'rubocop', require: false

  # Guards
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'guard-shell'
  gem 'guard-teaspoon'
  gem 'terminal-notifier-guard'
  #
  # Deployment
  gem 'capistrano', '~> 3.6.1'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'slackistrano'
  gem 'web-console', '~> 2.0'
end

group :development, :test do
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'factory_girl_rails'
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-nav'
  gem 'rspec-rails'
  gem 'sinatra'
  gem 'teaspoon-jasmine'

  # Spring preloader
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen'
end

group :test do
  # Fake ip-api.com server for specs (Geolocation)
  gem 'capybara_discoball'

  # Spec formatters
  gem 'rspec_junit_formatter'

  # Code coverage metrics
  gem 'codecov', require: false
  gem 'simplecov', require: false

  gem 'database_cleaner'
  gem 'launchy'
  gem 'rspec-retry'
  gem 'shoulda-matchers'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

group :production, :staging, :edge do
  # Loggly
  gem 'lograge'
  gem 'syslogger'
end
