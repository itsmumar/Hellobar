module ServiceProviders
  module Adapters
    class Base
      def self.inherited(base)
        base.prepend Rescuable
      end

      attr_reader :client
      class_attribute :key, :config

      def self.configure
        self.config = ActiveSupport::OrderedOptions.new
        yield config
      end

      def self.human_name
        name.demodulize
      end

      def initialize(client)
        @client = client
      end

      def lists
        []
      end

      def subscribe(list_id, params) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, 'to be implemented'
      end

      def batch_subscribe(list_id, subscribers, double_optin: nil)
        subscribers.each do |subscriber|
          subscribe list_id, double_optin.nil? ? subscriber : subscriber.merge(double_optin: double_optin)
        end
      end

      def tags
        []
      end

      def connected?
        lists.present?
      rescue => _
        false
      end

      def config
        self.class.config
      end
    end
  end
end
