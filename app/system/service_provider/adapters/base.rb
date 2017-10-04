module ServiceProvider::Adapters
  class Base
    prepend ServiceProvider::Rescuable

    def self.inherited(base)
      base.prepend ServiceProvider::Rescuable
      base.config = ActiveSupport::OrderedOptions.new
    end

    attr_reader :client
    class_attribute :key, :config

    rescue_from Net::HTTPServerException, Net::ReadTimeout, with: :ignore_error

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
    end

    def connected?
      test_connection
      true
    rescue StandardError => _
      false
    end

    def config
      self.class.config
    end

    private

    def test_connection
    end

    def notify_user_about_unauthorized_error
      DestroyIdentity.new(@identity, notify_user: true).call
    end

    def ignore_error(exception)
      tags = "[ServiceProvider] [#{ self.class.name.demodulize }]"
      Rails.logger.info "#{ tags } Exception ignored #{ exception.inspect }"
    end
  end
end
