class ServiceProvider
  prepend ServiceProvider::RailsLogger
  include ServiceProvider::Errors

  class << self
    def adapter(key)
      return if key.blank?
      ServiceProvider::Adapters.fetch(key.to_sym)
    end

    delegate :embed_code?, to: ServiceProvider::Adapters
  end

  attr_reader :remote_list_id

  delegate :lists, :tags, :config, :connected?, to: :adapter
  delegate :double_optin, to: :contact_list

  def initialize(identity, contact_list = nil)
    @identity = identity
    @contact_list = contact_list
    @remote_list_id = contact_list.data['remote_id'] if contact_list
  end

  def name
    adapter.key
  end

  def adapter
    @adapter ||=
      if adapter_class < ServiceProvider::Adapters::EmbedCode || adapter_class == ServiceProvider::Adapters::Webhook
        adapter_class.new(contact_list)
      else
        adapter_class.new(identity)
      end
  end

  def subscribe(email:, name: nil)
    return if email !~ Devise.email_regexp

    params = { email: email, name: name, tags: existing_tags, double_optin: double_optin }

    adapter.subscribe(remote_list_id, params).tap do
      adapter.assign_tags(contact_list) if adapter.is_a?(ServiceProvider::Adapters::GetResponse)
    end
  end

  private

  attr_reader :identity, :contact_list

  def adapter_class
    @adapter_class ||= self.class.adapter(identity&.provider || :hellobar)
  end

  def existing_tags
    (contact_list&.tags || []).select(&:present?)
  end
end
