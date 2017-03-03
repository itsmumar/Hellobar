module ServiceProviders
  class Maropost < ServiceProviders::Email
    attr_reader :identity

    def initialize(options = {})
      @identity = load_identity(options)
      @account_id, @api_key = load_credentials_from_identity

      @client = Faraday.new(url: Hellobar::Settings[:maropost_url]) do |faraday|
        faraday.request :json
        faraday.response :logger unless Rails.env.test?
        faraday.adapter Faraday.default_adapter
      end
    end

    def lists
      found_lists = []
      begin
        response = @client.get "accounts/#{@account_id}/lists.json",
          auth_token: @api_key,
          no_counts: true

        if response.success?
          response_hash = JSON.parse response.body
          found_lists = response_hash.collect { |list| { 'id' => list['id'], 'name' => list['name'] } }
        else
          error_message = response.body
          log "getting lists returned '#{error_message}' with the code #{response.status}"
        end

      rescue Faraday::TimeoutError
        log 'getting lists timed out'
      rescue => error
        log "getting lists raised #{error}"
      end

      found_lists
    end

    def subscribe(list_id, email, name = nil, _double_optin = true)
      if name
        first_name = name.split(' ')[0]
        last_name = name.split(' ')[1..-1].join(' ')
      else
        first_name = email
      end

      response = @client.post do |request|
        request.url "accounts/#{@account_id}/lists/#{list_id}/contacts.json"
        request.body = {
          auth_token: @api_key,
          contact: {
            first_name: first_name,
            last_name: last_name,
            email: email,
            subscribe: true,
            remove_from_dnm: true
          }
        }
      end

      if response.success?
        response
      else
        error_message = response.body
        log "sync error #{email} sync returned '#{error_message}' with the code #{response.status}"
      end

    rescue Faraday::TimeoutError
      log 'sync timed out'
    rescue => error
      log "sync raised #{error}"
    end

    def batch_subscribe(list_id, subscribers, _double_optin = true)
      subscribers.each do |subscriber|
        subscribe(list_id, subscriber[:email], subscriber[:name])
      end
    end

    private

    def load_identity(options)
      raise 'Must provide an identity' unless options[:identity] || options[:site]
      return options[:identity] if options[:identity]

      identity = options[:site].identities.find_by!(provider: 'maropost')
      return identity if identity

      raise 'Site does not have a stored Maropost identity'
    end

    def load_credentials_from_identity
      credentials = [identity.credentials && identity.credentials['username'], identity.api_key]

      raise 'Identity does not have a stored Maropost API key and AccountID' unless credentials.all?

      credentials
    end
  end
end
