module ServiceProvider::Adapters
  class Zapier < Webhook
    configure do |config|
      config.requires_webhook_url = true
    end
  end
end
