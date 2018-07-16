module ServiceProvider::Adapters
  class Zapier < Webhook
    configure do |config|
      config.requires_webhook_url = true
    end

    def determine_params(email:, name: nil)
      super.merge(contact_list: @contact_list.name)
    end
  end
end
