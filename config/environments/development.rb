Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Paperclip configuration (S3)
  settings = YAML.load_file('config/settings.yml')
  if settings['s3_bucket'] && settings['aws_access_key_id'] && settings['aws_secret_access_key']
    config.paperclip_defaults = {
      storage: :s3,
      s3_protocol: :https,
      s3_credentials: {
        bucket: settings['s3_bucket'],
        access_key_id: settings['aws_access_key_id'],
        secret_access_key: settings['aws_secret_access_key']
      }
    }
  end

  # Pony emailing configuration
  Pony.options = {
    from: 'Localhost: Hello Bar Support <support@localhost.com>',
    via: :smtp,
    via_options: {
      address: '127.0.0.1',
      port: 1025,
      authentication: :plain,
      domain: 'localhost'
    }
  }

  # Roadie emails
  config.roadie.url_options = { host: 'localhost', scheme: 'http', port: '3000' }
end
