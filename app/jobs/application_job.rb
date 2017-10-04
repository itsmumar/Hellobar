class ApplicationJob < ActiveJob::Base
  queue_as { "hb3_#{ Rails.env }_lowpriority" }

  rescue_from Aws::S3::Errors::InternalError, with: :retry_job

  rescue_from ActiveJob::DeserializationError do |exception|
    Shoryuken.logger.error exception
    Shoryuken.logger.error exception.backtrace.join("\n")
  end
end
