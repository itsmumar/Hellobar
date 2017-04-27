class QueueWorker
  STAGES = %w[edge staging production designqa].freeze
  VIEW_ATTRIBUTES = %w[ApproximateNumberOfMessages ApproximateNumberOfMessagesDelayed DelaySeconds].freeze
  LOG_FILE = Rails.root.join('log', 'queue_worker.log')

  module Delay
    def delay(task_name, options = {})
      queue = options.delete(:queue_name)
      namespace = options.delete(:namespace) || self.class.name
      body = "#{ namespace.underscore.downcase }:#{ task_name }[#{ id }]".gsub(/^:/, '')
      if Rails.env.development? || Rails.env.test?
        begin
          # Ensure private methods are called.
          method(task_name).call
        rescue NoMethodError => e
          raise e unless e.message.include?("undefined method `#{ task_name }'")
          raise "Not sure how to queue task '#{ body }' because there is no method #{ self.class }##{ task_name }: #{ $ERROR_INFO }"
        end
      else
        QueueWorker.send_sqs_message(body, nil, queue)
      end
    end
  end

  def self.queue_attributes(queue_name_filter = nil)
    sqs = AWS::SQS.new(
      access_key_id: Hellobar::Settings[:aws_access_key_id],
      secret_access_key: Hellobar::Settings[:aws_secret_access_key],
      logger: nil
    )

    queue_name_filter ||= Hellobar::Settings[:main_queue]
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

  def self.send_sqs_message(message, stage = nil, queue_name = nil)
    queue_name ||= Hellobar::Settings[:main_queue] || 'test_queue'
    stage ||= Hellobar::Settings[:env_name]

    raise ArgumentError, "Stage is required to be one of #{ STAGES }" unless STAGES.include?(stage)
    raise ArgumentError, 'Message must be defined' if message.blank?
    raise ArgumentError, 'Queue name must be defined' unless queue_name

    @sqs ||= AWS::SQS.new(
      access_key_id: Hellobar::Settings[:aws_access_key_id],
      secret_access_key: Hellobar::Settings[:aws_secret_access_key],
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
