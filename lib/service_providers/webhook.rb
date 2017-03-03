module ServiceProviders
  class Webhook < ServiceProvider
    attr_reader :contact_list

    def initialize(opts = {})
      @contact_list = opts[:contact_list]
    end

    def client
      @client ||= Faraday.new(url: contact_list.data['webhook_url']) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger unless Rails.env.test?
        faraday.adapter Faraday.default_adapter
      end
    end

    def subscribe(_, email, name = nil, double_optin = true)
      method = contact_list.data['webhook_method'].downcase.to_sym

      client.public_send(method) do |request|
        if method == :get
          request.params[:email] = email
          request.params[:name] = name
        else
          request.body = { name: name, email: email }
        end
      end
    end

    def batch_subscribe(_, subscribers, double_optin = true)
      subscribers.each do |subscriber|
        subscribe(nil, subscriber[:email], subscriber[:name])
      end
    end

    def valid?
      true
    end
  end
end
