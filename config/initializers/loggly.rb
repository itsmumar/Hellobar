require './config/initializers/settings'

# if Rails.env.production? && Hellobar::Settings[:loggly_url]
#   begin
#     loggly = Logglier.new(Hellobar::Settings[:loggly_url], threaded: true, format: :json)
#     Rails.logger.extend(ActiveSupport::Logger.broadcast(loggly))
#   rescue
#     Rails.logger.info 'Error starting Loggly'
#   end
# end

# require 'syslogger'
# config.
# config.lograge.enabled = true
# config.lograge.formatter = Lograge::Formatters::Json.new

# if Hellobar::Settings[:loggly_url]

  Rails.application.configure do

    # Enable Lograge styling of logs
    config.lograge.enabled = true

    # with JSON output
    config.lograge.formatter = Lograge::Formatters::Json.new

    # Support for regular format when logging to file [perhaps unnecessary here]
    config.lograge.keep_original_rails_log = true

    # Log reuqest params
    config.lograge.custom_options = lambda do |event|
      exceptions = %w(controller action format id)
      Hash[params: event.payload[:params].except(*exceptions)]
    end

    config.lograge.logger = Syslogger.new('hellobar', Syslog::LOG_PID, Syslog::LOG_LOCAL7)



    # syslogger =

    # config.logger = syslogger



  end

  # Rails.logger.extend(ActiveSupport::Logger.broadcast(syslogger))
# end
