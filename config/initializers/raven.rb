Raven.configure do |config|
  config.dsn = Hellobar::Settings[:sentry_dsn] if Hellobar::Settings[:sentry_dsn].present?

  # filter sensitive data
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

  # enable only on production/staging/edge environments
  config.environments = %w[production staging edge]

  # don't log readiness
  config.silence_ready = true
end
