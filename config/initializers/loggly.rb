require './config/initializers/settings'

if defined? Lograge
  Rails.application.configure do
    # Enable Lograge styling of logs
    config.lograge.enabled = true

    # with JSON output
    config.lograge.formatter = Lograge::Formatters::Json.new

    # Support for regular format when logging to file
    config.lograge.keep_original_rails_log = true

    # Log request params
    config.lograge.custom_options = lambda do |event|
      exceptions = %w[controller action format id]
      Hash[params: event.payload[:params].except(*exceptions)]
    end

    # Make Syslogger the default logger
    config.lograge.logger = Syslogger.new 'hellobar', Syslog::LOG_PID, Syslog::LOG_LOCAL7
  end
end
