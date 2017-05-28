module ServiceProviders
  module Adapters
    class Base
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

      def subscribe(contact) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, 'to be implemented'
      end

      def batch_subscribe(contacts) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, 'to be implemented'
      end

      def config
        self.class.config
      end
    end
  end
end
