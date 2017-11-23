require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hellobar
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Require Settings early on in the boot process
    require Rails.root.join('app', 'system', 'settings')

    # We'll handle our own errors
    config.exceptions_app = routes

    # We'd prefer to use initializers to load the files from the /lib
    # directory that we need. This way we have more control over load
    # order and have a convenient place to put other initialization
    # code (config, etc.)
    config.autoload_paths += Dir[config.root.join('app', 'models', '**/')]

    # Action Mailer
    config.action_mailer.default_url_options = { host: Settings.host }

    # Devise
    config.to_prepare do
      Devise::SessionsController.layout proc { |_| action_name == 'new' ? 'static' : 'application' }
    end

    # Use Shoryuken as ActiveJob adapter
    config.active_job.queue_adapter = :shoryuken

    # Configure SMTP for Mailers
    config.action_mailer.smtp_settings = {
      address: 'smtp.sendgrid.net',
      port: 587,
      enable_starttls_auto: true,
      user_name: Settings.sendgrid_user_name,
      password: Settings.sendgrid_password,
      authentication: :plain,
      domain: Settings.host
    }

    # Configure CORS
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins Settings.campaigns_url

        resource '/api/*', headers: :any,
          methods: %i[get post delete put patch options head]
      end
    end
  end
end
