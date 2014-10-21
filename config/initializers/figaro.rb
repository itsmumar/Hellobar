# config/initializers/figaro.rb

Figaro.require_keys("secret_key_base", "sentry_dsn") if Rails.env.production? && !Rake.running?
