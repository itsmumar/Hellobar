Shoryuken.configure_client do |config|
  config.sqs_client = Aws::SQS::Client.new
end

Shoryuken.configure_server do |config|
  config.sqs_client = Aws::SQS::Client.new

  Rails.logger = Shoryuken::Logging.logger
  Rails.logger.level = Rails.application.config.log_level
end
