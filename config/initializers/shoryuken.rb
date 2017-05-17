Shoryuken.configure_client do |config|
  config.sqs_client = Aws::SQS::Client.new
end

Shoryuken.configure_server do |config|
  config.sqs_client = Aws::SQS::Client.new

  if Rails.application.config.respond_to? :lograge
    Shoryuken::Logging.logger = Rails.application.config.lograge.logger
    Rails.logger = Rails.application.config.lograge.logger
  else
    Rails.logger = Shoryuken::Logging.logger
  end
end

# this is needed to avoid parsing errors
# will be removed when we refactor hellobar_backend
class CustomWorkerRegistry < Shoryuken::DefaultWorkerRegistry
  def fetch_worker(queue, message)
    return SyncOneContactListWorker.new if SyncOneContactListWorker.parse(message.body)
    super
  end
end

Shoryuken.worker_registry = CustomWorkerRegistry.new
