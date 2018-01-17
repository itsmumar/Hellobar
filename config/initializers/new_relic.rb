if defined?(NewRelic)
  module DynamoDB::NewRelicTracer
    def send_request(method, request)
      callback = proc do |_result, _metrics, elapsed|
        if request[:key_condition_expression]
          NewRelic::Agent::Datastores.notice_statement(request[:key_condition_expression], elapsed)
        end
      end

      NewRelic::Agent::Datastores.wrap(self.class.name, method, request[:table_name], callback) do
        super
      end
    end
  end

  DynamoDB.send(:prepend, DynamoDB::NewRelicTracer)
end
