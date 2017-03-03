require './config/initializers/settings'

if Rails.env.production? && Hellobar::Settings[:loggly_url]
  begin
    loggly = Logglier.new(Hellobar::Settings[:loggly_url], threaded: true, format: :json)
    Rails.logger.extend(ActiveSupport::Logger.broadcast(loggly))
  rescue
    puts 'Error starting Loggly'
  end
end
