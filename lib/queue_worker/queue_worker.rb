# load rake tasks for QueueWorker
Rails.application.load_tasks if Rails.env.development? || Rails.env.test?

class QueueWorker
  VIEW_ATTRIBUTES = %w[ApproximateNumberOfMessages ApproximateNumberOfMessagesDelayed DelaySeconds].freeze
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

  def self.queue_attributes(queue_name_filter = nil)
    sqs = AWS::SQS.new(
      access_key_id: Settings.aws_access_key_id,
      secret_access_key: Settings.aws_secret_access_key,
      logger: nil
    )

    queue_name_filter ||= Settings.main_queue
    queues = filtered_queues(sqs, queue_name_filter)

    queues.collect do |queue|
      sqs.client.queue_attributes(queue_url: queue.url, attribute_names: VIEW_ATTRIBUTES)
    end
  end

  def self.filtered_queues(sqs_interface, queue_name_filter)
    raise 'requires an instance of AWS::SQS' unless sqs_interface.is_a?(AWS::SQS)

    sqs_interface.queues.select do |queue|
      queue.url.split('/').last.include?(queue_name_filter)
    end
  end

  def self.send_sqs_message(message, queue_name = nil)
    queue_name ||= Settings.main_queue || 'test_queue'

    raise ArgumentError, 'Message must be defined' if message.blank?
    raise ArgumentError, 'Queue name must be defined' unless queue_name

    @sqs ||= AWS::SQS.new(
      access_key_id: Settings.aws_access_key_id,
      secret_access_key: Settings.aws_secret_access_key,
      logger: nil
    )

    @queue ||= @sqs.queues.find do |q|
      q.url.split('/').last == queue_name
    end

    Rails.logger.info "[#{ Time.current }] Sending #{ message } to #{ @queue.url }"
    receipt = @queue.send_message(message)
    Rails.logger.info receipt.to_s
  end
end
