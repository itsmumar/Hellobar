if defined? Raven
  Raven.configure do |config|
    config.dsn = Hellobar::Settings[:sentry_dsn] if Hellobar::Settings[:sentry_dsn].present?

    # filter sensitive data
    config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  end
end
