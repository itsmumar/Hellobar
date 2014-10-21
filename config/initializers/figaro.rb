# config/initializers/figaro.rb
puts "Initialized"
Figaro.require_keys("secret_key_base", "sentry_dsn")
