class QueueWorker
end

class QueueWorker
  module Delay
    def delay task_name, options={}
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
        stage = Hellobar::Settings[:env_name]
        raise 'Stage not set -- you must add :env_name to settings.yml' unless stage.present?
        `bundle exec script/send_sqs_message #{stage} '#{body}'`
      end
    end
  end
end
