Shoryuken.configure_client do |config|
  config.sqs_client = Aws::SQS::Client.new
end

Shoryuken.configure_server do |config|
  config.sqs_client = Aws::SQS::Client.new

  Rails.logger = Shoryuken::Logging.logger
  Rails.logger.level = Rails.application.config.log_level

  config.server_middleware do |chain|
    chain.add RavenMiddleware
  end
end

class RavenMiddleware
  include Shoryuken::Util

  def call(worker, queue, sqs_msg, body)
    yield
  rescue => e
    Raven.capture_exception(e, extra: { message: sqs_msg.as_json, worker: worker_name(worker.class, sqs_msg, body), queue: queue })
    raise e
  end
end

# this is needed to avoid parsing errors
# will be removed when we refactor hellobar_backend
class CustomWorkerRegistry < Shoryuken::DefaultWorkerRegistry
  def fetch_worker(queue, message)
    return SubscribeContactWorker.new if SubscribeContactWorker.parse(message.body)
    super
  rescue => _
    Raven.capture_message('Could not parse sqs message', extra: { message: message.body, sqs_msg: message.as_json })
    Rails.logger.error "Could not parse sqs message: #{ message.body }; #{ message.as_json }"
  end
end

Shoryuken.worker_registry = CustomWorkerRegistry.new
