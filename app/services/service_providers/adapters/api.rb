module ServiceProviders
  module Adapters
    class Api < Base
      def batch_subscribe(list_id, subscribers, double_optin: nil)
        subscribers.each do |subscriber|
          subscribe list_id, double_optin.nil? ? subscriber : subscriber.merge(double_optin: double_optin)
        end
      end
    end
  end
end
