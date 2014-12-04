Raven.configure do |config|
  config.dsn = Hellobar::Settings[:sentry_dsn] unless Hellobar::Settings[:sentry_dsn].blank?
end
