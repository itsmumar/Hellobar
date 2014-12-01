Raven.configure do |config|
  config.dsn = Hellobar::Settings[:sentry_dsn]
end
