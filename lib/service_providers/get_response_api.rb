module ServiceProviders
  class GetResponseApi < ServiceProviders::Email

    def initialize(opts = {})
      if opts[:identity]
        identity = opts[:identity]
      elsif opts[:site]
        identity = opts[:site].identities.find_by_provider!('get_response_api')
        raise "Site does not have a stored GetResponse identity" unless identity
      else
        raise "Must provide an identity through the arguments"
      end

      @contact_list = opts[:contact_list]

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

    def lists(strict = false)
      found_lists = []
      begin
        response = @client.get 'campaigns', { perPage: 500 }

        if response.success?
          response_hash = JSON.parse response.body
          found_lists = response_hash.map {|list| {'id' => list['campaignId'], 'name' => list['name']}}
        else
          error_message = JSON.parse(response.body)['codeDescription']
          log "getting lists returned '#{error_message}' with the code #{response.status}"
          raise error_message if strict && response.status == 401
        end

      rescue Faraday::TimeoutError
        log "getting lists timed out"
      rescue => error
        log "getting lists raised #{error}"
        raise error if strict && error.message == "Authorization Failed"
      end
      found_lists
    end

    def subscribe(list_id, email, name = nil, double_optin = true)
      name ||= email

      if @contact_list.present?
        cycle_day = @contact_list.data['cycle_day']
        cycle_day = cycle_day.present? ? cycle_day.to_i : nil
      end

      begin
        request_body = {name: name, email: email, campaign: {campaignId: list_id}}
        request_body.merge({dayOfCycle: cycle_day}) if cycle_day

        response = @client.post do |request|
          request.url 'contacts'
          request.body = request_body
        end

        if response.success?
          response
        else
          error_message = JSON.parse(response.body)['codeDescription']
          log "sync error #{email} sync returned '#{error_message}' with the code #{response.status}"
        end

      rescue Faraday::TimeoutError
        log "sync timed out"
      rescue => error
        log "sync raised #{error}"
      end
    end

    def batch_subscribe(list_id, subscribers, double_optin = true)
      subscribers.each do |subscriber|
        subscribe(list_id, subscriber[:email], subscriber[:name])
      end
    end

    def valid?
      lists(true)
      true
    rescue
      false
    end
  end
end
