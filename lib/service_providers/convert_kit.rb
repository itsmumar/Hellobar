module ServiceProviders
  class ConvertKit < ServiceProviders::Email
    def initialize(opts = {})
      if opts[:identity]
        identity = opts[:identity]
      elsif opts[:site]
        identity = opts[:site].identities.find_by_provider!('convert_kit')
        raise 'Site does not have a stored ConvertKit identity' unless identity
      else
        raise 'Must provide an identity through the arguments'
      end

      @contact_list = opts[:contact_list]
      @identity = identity

      api_key = @identity.api_key
      raise 'Identity does not have a stored ConvertKit API secret key' unless api_key

      client_settings = {
        url: 'https://api.convertkit.com/v3/'
      }

      @client = Faraday.new(client_settings) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger unless Rails.env.test?
        faraday.adapter Faraday.default_adapter
      end
    end

    def lists
      response = make_api_call('get', 'forms')

      if response.success?
        response_hash = JSON.parse response.body
        response_hash['forms'].map { |form| { 'id' => form['id'], 'name' => form['name'] } }
      else
        error_message = JSON.parse(response.body)['error']
        log "getting forms returned '#{error_message}' with the code #{response.status}"
        raise error_message
      end
    end

    def tags
      response = make_api_call('get', 'tags')

      if response.success?
        response_hash = JSON.parse response.body
        response_hash['tags'].map { |tag| { 'id' => tag['id'], 'name' => tag['name'] } }
      else
        error_message = JSON.parse(response.body)['error']
        log "getting tags returned '#{error_message}' with the code #{response.status}"
        raise error_message
      end
    end

    # NOTE: `double_optin` depends on the ConvertKit account form settings.
    # No effect of `double_optin` from API
    def subscribe(form_id, email, name = nil, _double_optin = false)
      body = {
        api_key: @identity.api_key,
        email: email,
        tags: @contact_list.tags.join(',')
      }

      if name.present?
        split = name.split(' ', 2)
        lname = split[1]

        body[:first_name] = split[0]
        body[:fields] = { last_name: lname } if lname
      end

      begin
        response = make_api_call('post', "forms/#{form_id}/subscribe", body: body)

        if response.success?
          response
        else
          error_message = JSON.parse(response.body)['error']
          log "sync error #{email} sync returned '#{error_message}' with the code #{response.status}"
        end

      rescue Faraday::TimeoutError
        log 'sync timed out'
      rescue => error
        log "sync raised #{error}"
      end
    end

    # NOTE: `double_optin` depends on the ConvertKit account form settings.
    # No effect of `double_optin` from API
    def batch_subscribe(form_id, subscribers, _double_optin = false)
      subscribers.each do |subscriber|
        subscribe(form_id, subscriber[:email], subscriber[:name])
      end
    end

    def valid?
      !!lists
    rescue => error
      log "getting tags raised #{error}"
      false
    end

    private

    def make_api_call(method, path, options = {})
      path += "?api_secret=#{@identity.api_key}"

      case method
      when 'get'
        @client.get path
      when 'post'
        @client.post path, options[:body]
      end
    end
  end
end
