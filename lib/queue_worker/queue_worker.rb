class QueueWorker
  STAGES = %w(edge staging production)

  module Delay
    def delay(task_name, options={})
      namespace = options.delete(:namespace) || self.class.name
      body = "#{namespace.underscore.downcase}:#{task_name}[#{id}]".gsub(/^:/,'')
      if Rails.env.development? || Rails.env.test?
        begin
          # Ensure private methods are called.
          self.method(task_name).()
        rescue NoMethodError => e
          if e.message.include?("undefined method `#{task_name}'")
            raise "Not sure how to queue task '#{body}' because there is no method #{self.class}##{task_name}: #{$!}"
          else
            raise e
          end
        end
      else
        QueueWorker.send_sqs_message(body)
      end
    end
  end

  def self.send_sqs_message(message, stage=nil, queue_name=nil)
    queue_name ||= Hellobar::Settings[:main_queue] || 'test_queue'
    stage ||= Hellobar::Settings[:env_name]

    raise ArgumentError, "Stage is required to be one of #{STAGES}" unless STAGES.include?(stage)
    raise ArgumentError, "Message must be defined" unless message && message.length > 0
    raise ArgumentError, "Queue name must be defined" unless queue_name

    @sqs ||= AWS::SQS.new(access_key_id: Hellobar::Settings[:aws_access_key_id], secret_access_key: Hellobar::Settings[:aws_secret_access_key])
    @queue ||= sqs.queues.find do |q|
      q.url.split('/').last == queue_name
    end

    Rails.logger.info "[#{Time.now}] Sending #{message} to #{queue.url}"
    receipt = queue.send_message(message)
    Rails.logger.info receipt.to_s
  end
end
