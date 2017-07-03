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

    def initialize(identity = nil, client = nil)
      @identity = identity
      @client = client
    end

    def lists
      []
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

    def notify_user_about_unauthorized_error
      @identity.destroy_and_notify_user
    end

    def ignore_error(exception)
      tags = "[ServiceProvider] [#{ self.class.name.demodulize }]"
      Rails.logger.info "#{ tags } Exception ignored #{ exception.inspect }"
    end
  end
end
