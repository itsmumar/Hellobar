module ServiceProviders
  module Adapters
    class Api < Base
      def lists
        raise NoMethodError, 'to be implemented'
      end

      def subscribe(list_id, contact) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, 'to be implemented'
      end

      def batch_subscribe(list_id, subscribers, double_optin: nil)

        subscribers.each do |subscriber|
          subscribe list_id, double_optin.nil? ? subscriber : subscriber.merge(double_optin: double_optin)
        end
      end
    end
  end
end
