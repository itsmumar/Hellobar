module ServiceProviders
  class Provider
    mattr_reader :config do
      ActiveSupport::OrderedOptions.new { |hash, k| hash[k] = ActiveSupport::OrderedOptions.new }
    end

    mattr_reader :adapters do
      {}
    end

    def self.adapter(key)
      adapters.fetch(key.to_sym)
    end

    def self.register(adapter, klass)
      adapters.update adapter.to_sym => klass
    end

    def self.configure
      yield config
    end

    attr_reader :adapter

    def initialize(identity, contact_list = nil)
      @adapter = self.class.adapter(identity.provider).new(identity)
      @identity = identity
      @contact_list = contact_list
    end

    def name
      @adapter.class.name.demodulize
    end

    def valid?
      true
    end
  end
end
