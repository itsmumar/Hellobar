# config/initializers/figaro.rb

Figaro.require_keys("secret_key_base", "sentry_dsn", "rotp_secret_key_base") if Rails.env.production? && !Rake.running?
