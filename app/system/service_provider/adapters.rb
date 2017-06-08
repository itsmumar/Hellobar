class ServiceProvider
  module Adapters
    mattr_reader :registry do
      {}
    end

    def self.embed_code?(provider)
      adapter = fetch(provider)
      adapter.config.requires_embed_code
    end

    def self.oauth?(provider)
      adapter = fetch(provider)
      adapter.config.oauth
    end

    def self.api_key?(provider)
      adapter = fetch(provider)
      adapter.config.requires_api_key
    end

    def self.app_url?(provider)
      adapter = fetch(provider)
      adapter.config.requires_app_url
    end

    def self.enabled
      all.reject { |a| a.config.disabled }
    end

    def self.all
      registry.values
    end

    def self.keys
      registry.keys
    end

    def self.fetch(key)
      registry.fetch(key.to_sym)
    end

    def self.register(adapter, klass)
      registry.update adapter.to_sym => klass
      klass.key = adapter
    end

    register :aweber, Adapters::Aweber
    register :active_campaign, Adapters::ActiveCampaign
    register :createsend, Adapters::CampaignMonitor
    register :constantcontact, Adapters::ConstantContact
    register :convert_kit, Adapters::ConvertKit
    register :drip, Adapters::Drip
    register :get_response_api, Adapters::GetResponse
    register :icontact, Adapters::IContact
    register :infusionsoft, Adapters::Infusionsoft
    register :mad_mimi_api, Adapters::MadMimi
    register :mad_mimi_form, Adapters::MadMimiForm
    register :mailchimp, Adapters::MailChimp
    register :maropost, Adapters::Maropost
    register :my_emma, Adapters::MyEmma
    register :verticalresponse, Adapters::VerticalResponse
    register :vertical_response, Adapters::VerticalResponseForm
    register :webhooks, Adapters::Webhook
  end
end
