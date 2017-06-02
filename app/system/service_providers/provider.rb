module ServiceProviders
  class Provider
    prepend RavenLogger

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

    def initialize(contact_list)
      @adapter = determine_adapter(contact_list)
      @contact_list = contact_list
    end

    def name
      adapter.key
    end

    delegate :lists, to: :adapter

    def subscribe(list_id, email:, name: nil)
      params = { email: email, name: name, tags: @contact_list&.tags || [], double_optin: @contact_list&.double_optin }

      adapter.subscribe(list_id, params).tap do
        adapter.assign_tags(@contact_list) if adapter.is_a?(Adapters::GetResponse)
      end
    end

    def batch_subscribe(list_id, subscribers)
      adapter.batch_subscribe(list_id, subscribers, double_optin: @contact_list&.double_optin)
    end

    private

    def determine_adapter(contact_list)
      adapter_class = self.class.adapter(contact_list.identity.provider)

      if adapter_class < Adapters::EmbedForm || adapter_class == Adapters::Webhook
        adapter_class.new(contact_list)
      else
        adapter_class.new(contact_list.identity)
      end
    end
  end
end
