require "./config/initializers/settings"

if Rails.env.production?
  LogglyLogger = Logglier.new(Hellobar::Settings[:loggly_url]) rescue Rails.logger
else
  LogglyLogger = Rails.logger
end
