module ServiceProviders
  class Provider
    prepend ServiceProviders::Logger
    prepend ServiceProviders::RavenLogger

    mattr_reader :config do
      ActiveSupport::OrderedOptions.new { |hash, k| hash[k] = ActiveSupport::OrderedOptions.new }
    end

    def self.adapter(key)
      Adapters.fetch(key.to_sym)
    end

    def self.configure
      yield config
    end

    attr_reader :adapter, :remote_list_id

    def initialize(identity, contact_list = nil)
      @adapter = determine_adapter(identity, contact_list)
      @identity = identity
      @contact_list = contact_list
      @remote_list_id = contact_list.data['remote_id'] if contact_list
    end

    def human_name
      I18n.t(name, scope: :service_providers)
    end

    def name
      adapter.key
    end

    delegate :lists, :tags, to: :adapter

    def subscribe(email:, name: nil)
      params = { email: email, name: name, tags: @contact_list&.tags || [], double_optin: @contact_list&.double_optin }

      adapter.subscribe(remote_list_id, params).tap do
        adapter.assign_tags(@contact_list) if adapter.is_a?(Adapters::GetResponse)
      end
    end

    def batch_subscribe(subscribers)
      adapter.batch_subscribe(remote_list_id, subscribers, double_optin: @contact_list&.double_optin)
    end

    def connected?
      adapter.connected?
    end

    private

    def determine_adapter(identity, contact_list)
      adapter_class = self.class.adapter(identity.provider)

      if adapter_class < Adapters::EmbedCode || adapter_class == Adapters::Webhook
        adapter_class.new(contact_list)
      else
        adapter_class.new(identity)
      end
    end
  end
end
