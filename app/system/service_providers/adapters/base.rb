module ServiceProviders
  module Adapters
    class Base
      def self.inherited(base)
        base.prepend Rescuable
      end

      attr_reader :client
      class_attribute :key

      def self.config
        ServiceProviders::Provider.config.send(key)
      end

      def self.register(name)
        Provider.register name, self
        self.key = name
      end

      def initialize(client)
        @client = client
      end

      def lists
        raise NoMethodError, 'to be implemented'
      end

      def subscribe(list_id, params) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, 'to be implemented'
      end

      def batch_subscribe(list_id, subscribers, double_optin: nil) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, 'to be implemented'
      end

      def config
        self.class.config
      end
    end
  end
end
