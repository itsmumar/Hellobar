module ServiceProvider::Adapters
  class Base
    def self.inherited(base)
      base.prepend ServiceProvider::Rescuable
      base.config = ActiveSupport::OrderedOptions.new
    end

    attr_reader :client
    class_attribute :key, :config

    def self.configure
      yield config
    end

    def initialize(client)
      @client = client
    end

    def lists
      []
    end

    def subscribe(params) # rubocop:disable Lint/UnusedMethodArgument
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
      test_connection
      true
    rescue => _
      false
    end

    def config
      self.class.config
    end

    private

    def test_connection
    end
  end
end
