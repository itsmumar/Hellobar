module ServiceProviders
  class GetResponseApi < ServiceProviders::Email

    def initialize(opts = {})
      if opts[:identity]
        identity = opts[:identity]
      elsif opt[:site]
        identity = opts[:site].identities.where(:provider => 'get_response_api').first
        raise "Site does not have a stored GetResponse identity" unless identity
      end

      api_key = identity.api_key
      raise "Identity does not have a stored GetResponse API key" unless api_key

      client_settings = {
        url: Hellobar::Settings[:get_response_api_url],
        headers: { 'X-Auth-Token' => "api-key #{api_key}"}
      }

      @client = Faraday.new(client_settings) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
    end

    def lists
      response = @client.get 'campaigns'
      if response.success?
        response_hash = JSON.parse response.body
        response_hash.map {|list| {'id' => list['campaignId'], 'name' => list['name']}}
      else
        error_message = JSON.parse(response.body)['codeDescription']
        log "sync error #{email} sync returned '#{error_message}' with the code #{response.status}"
      end
    end

    def subscribe(list_id, email, name = nil, double_optin = true)
      response = @client.post do |request|
        request.url 'contacts'
        request.body = {name: name, email: email, campaign: {campaignId: list_id}}
      end

      if response.success?
        response
      else
        error_message = JSON.parse(response.body)['codeDescription']
        log "sync error #{email} sync returned '#{error_message}' with the code #{response.status}"
      end
    end

    def batch_subscribe(list_id, subscribers, double_optin = true)
      subscribers.each do |subscriber|
        subscribe(list_id, subscriber[:email], subscriber[:name])
      end
    end
  end
end
