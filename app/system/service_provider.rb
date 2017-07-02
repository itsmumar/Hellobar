class ServiceProvider
  prepend ServiceProvider::RailsLogger
  prepend ServiceProvider::RavenLogger
  include ServiceProvider::Errors

  class << self
    def adapter(key)
      return if key.blank?
      Adapters.fetch(key.to_sym)
    end

    delegate :embed_code?, to: ServiceProvider::Adapters
  end

  attr_reader :adapter, :remote_list_id

  def initialize(identity, contact_list = nil)
    @adapter = determine_adapter(identity, contact_list)
    @identity = identity
    @contact_list = contact_list
    @remote_list_id = contact_list.data['remote_id'] if contact_list
  end

  def name
    adapter.key
  end

  delegate :lists, :tags, :config, :connected?, to: :adapter

  def subscribe(email:, name: nil)
    return if email !~ Devise.email_regexp

    params = { email: email, name: name, tags: existing_tags, double_optin: @contact_list&.double_optin }

    adapter.subscribe(remote_list_id, params).tap do
      adapter.assign_tags(@contact_list) if adapter.is_a?(Adapters::GetResponse)
    end
  end

  private

  def determine_adapter(identity, contact_list)
    adapter_class = self.class.adapter(identity&.provider || :hellobar)

    if adapter_class < Adapters::EmbedCode || adapter_class == Adapters::Webhook
      adapter_class.new(contact_list)
    else
      adapter_class.new(identity)
    end
  end

  def existing_tags
    (@contact_list&.tags || []).select(&:present?)
  end
end
