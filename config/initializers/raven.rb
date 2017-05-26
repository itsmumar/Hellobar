Raven.configure do |config|
  config.dsn = Settings.sentry_dsn if Settings.sentry_dsn.present?

  # filter sensitive data
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

  # enable only on production/staging/edge environments
  config.environments = %w[production staging edge]

  # don't log readiness
  config.silence_ready = true

  config.async = ->(event) { SentryJob.perform_later(event.to_hash) }
end
