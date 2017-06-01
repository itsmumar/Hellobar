Raven.configure do |config|
  config.dsn = Settings.sentry_dsn if Settings.sentry_dsn.present?

  # filter sensitive data
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

  # enable only on production/staging/edge environments
  config.environments = %w[production staging edge]

  # don't log readiness
  config.silence_ready = true

  # send events ansychronously
  # (in Thin it won't make a difference but it might in Puma)
  config.async = ->(event) { Thread.new { Raven.send_event(event) } }
end
