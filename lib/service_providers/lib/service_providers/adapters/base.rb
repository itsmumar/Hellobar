module ServiceProviders
  module Adapters
    class Base
      attr_reader :client

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
        ServiceProviders.config
      end
    end
  end
end
