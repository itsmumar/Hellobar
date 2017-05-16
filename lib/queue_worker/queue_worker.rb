# load rake tasks for QueueWorker
Rails.application.load_tasks if Rails.env.development? || Rails.env.test?

class QueueWorker
  LOG_FILE = Rails.root.join('log', 'queue_worker.log')

  module Delay
    def delay(task_name, options = {})
      queue = options.delete(:queue_name)
      namespace = options.delete(:namespace) || self.class.name
      task = "#{ namespace.underscore.downcase }:#{ task_name }".gsub(/^:/, '')
      body = "#{ task }[#{ id }]".gsub(/^:/, '')

      return QueueWorker.send_sqs_message(body, queue) unless Rails.env.development? || Rails.env.test?

      if Rake::Task.task_defined?(task)
        Rake::Task[task].reenable
        Rake::Task[task].invoke(id)
      elsif respond_to?(task_name, true)
        send(task_name)
      else
        raise "couldn't find task #{ task }"
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
