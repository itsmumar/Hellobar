source 'https://rubygems.org'

gem 'rails', '4.1.16'

# AWS
gem 'aws-sdk'
gem 'fog-aws'

# Authentication / authorization
gem 'devise'
gem 'google-api-client'
gem 'omniauth', '~> 1.0'

# OTP Authentication (One Time Passwords)
gem 'rotp'
gem 'rqrcode'
gem 'ruby-hmac'

# Email integrations
gem 'active_campaign', '~> 0.1.14'
gem 'aweber'
gem 'constantcontact'
gem 'createsend' # CampaignMonitor
gem 'drip-ruby', require: 'drip'
gem 'gibbon' # MailChimp
gem 'infusionsoft'
gem 'madmimi'
gem 'omniauth-aweber', '~> 1.0'
gem 'omniauth-constantcontact2', '~> 1.0'
gem 'omniauth-createsend', '~> 1.0'
gem 'omniauth-google-oauth2', '~> 0.2.6'
gem 'omniauth-mailchimp', github: 'floomoon/omniauth-mailchimp', ref: '239e08d3297cf637b5b0b77b419fdc8461239378'
gem 'omniauth-verticalresponse', '~> 1.0.0'
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
gem 'fontcustom'
gem 'handlebars_assets' # Handlebars templates in Rails assets pipeline (js modals)
gem 'jquery-rails'
gem 'jwt'
gem 'mini_racer'
gem 'mustache'
gem 'rails-html-sanitizer'
gem 'sassc-rails'
gem 'simple_form'
gem 'slim-rails'
gem 'sprockets'
gem 'sprockets-es6'

# ActiveRecord / Database
gem 'kaminari'
gem 'mysql2', '~> 0.3.18'

# File uploads
gem 'paperclip'

# JSON
gem 'active_model_serializers'
gem 'jbuilder'
gem 'oj'
gem 'oj_mimic_json'

# PDFs
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

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
gem 'signet'
gem 'thread'
gem 'uglifier'
gem 'unf'
gem 'whenever'
gem 'zip-zip' # will load compatibility for old rubyzip API.

gem 'analytics-ruby', require: 'segment/analytics'

# Be very careful with upgrading rake as version 11 changes the way passing
# param works and double dashes in queue_worker no longer work
gem 'rake', '~> 10.3.2'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'

  # Static code analysis
  gem 'brakeman', require: false
  gem 'rubocop', require: false

  # Remove when we upgrade to sprockets-rails 3.1+ (and add `config.assets.quiet = true`)
  gem 'quiet_assets'

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
end

group :development, :test do
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'factory_girl_rails'
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-nav'
  gem 'rspec-rails'
  gem 'simplecov'
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
