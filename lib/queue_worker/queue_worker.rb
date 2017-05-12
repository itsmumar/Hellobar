class QueueWorker
  LOG_FILE = Rails.root.join('log', 'queue_worker.log')

  module Delay
    def delay(task_name, options = {})
      queue = options.delete(:queue_name)
      namespace = options.delete(:namespace) || self.class.name
      body = "#{ namespace.underscore.downcase }:#{ task_name }[#{ id }]".gsub(/^:/, '')
      if Rails.env.development? || Rails.env.test?
        begin
          Rake::Task["#{ namespace.underscore.downcase }:#{ task_name }"].reenable
          Rake::Task["#{ namespace.underscore.downcase }:#{ task_name }"].invoke(id)
        rescue RuntimeError => e
          # Ensure private methods are called.
          method(task_name).call if e.message.include?("Don't know how to build task")
        end
      else
        QueueWorker.send_sqs_message(body, queue)
      end
    end
  end

  def self.send_sqs_message(message, queue_name = nil)
    queue_name ||= Settings.main_queue || 'test_queue'

    raise ArgumentError, 'Message must be defined' if message.blank?
    raise ArgumentError, 'Queue name must be defined' unless queue_name

    @queue ||= sqs.get_queue_by_name(queue_name: queue_name)

    Rails.logger.info "[#{ Time.current }] Sending #{ message } to #{ @queue.url }"
    receipt = @queue.send_message(message_body: message)
    Rails.logger.info receipt.message_id.to_s
  end

  def self.sqs
    @sqs ||= Aws::SQS::Resource.new
  end
end
