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

      @api_key = identity.api_key
      raise "Identity does not have a stored GetResponse API key" unless api_key
    end

    def lists
      fetch_resource('campaign')
    end

    def tags
      fetch_resource('tag')
    end

    def subscribe(list_id, email, name = nil, double_optin = true)
      name ||= email
      tags = []

      if contact_list.present?
        tags = contact_list.tags.map { |tag| { tagId: tag } }
        cycle_day = contact_list.data['cycle_day']
        cycle_day = cycle_day.present? ? cycle_day.to_i : nil
      end

      begin
        request_body = {
          name: name,
          email: email,
          campaign: {
            campaignId: list_id
          }
        }

        request_body.merge({ dayOfCycle: cycle_day }) if cycle_day

        response = client.post 'contacts', request_body

        if response.success?
          if tags.any?
            # In GetResponse you cannot assign tags to contacts sent via API,
            # however you can assign tags to existing contacts in the list, so
            # we will tag the two most recently added contacts (we could tag
            # only the most recent one, but there could be some race conditions)
            # This is a little bit of a hack, but it should give us 95% of what
            # is required when it comes to tagging.
            # We add tags only to contacts which are also stored at HelloBar,
            # so that unknown origin contacts at GR won’t get tagged by us
            # https://crossover.atlassian.net/browse/XOHB-1397
            contacts = fetch_latest_contacts(20)
            subscribers = @contact_list.subscribers(10)

            find_union(contacts, subscribers, 2).each do |contact|
              assign_tags contact_id: contact["contactId"], tags: tags
            end
          else
            response
          end
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
      !!lists
    rescue => error
      log "Getting lists raised #{error}"
      false
    end

    private

    attr_reader :api_key, :contact_list

    def client
      @client ||= Faraday.new(client_settings) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger unless Rails.env.test?
        faraday.adapter Faraday.default_adapter
      end
    end

    def client_settings
      @client_settings ||= {
        url: Hellobar::Settings[:get_response_api_url],
        headers: {
          'X-Auth-Token' => "api-key #{ api_key }"
        }
      }
    end

    def find_union(contacts, subscribers, count = 2)
      found_contacts = []

      contacts.each do |contact|
        subscribers.map do |subscriber|
          found_contacts << contact if subscriber[:email] == contact["email"]
        end

        break if found_contacts.count >= count
      end

      found_contacts
    end

    def fetch_resource(resource)
      response = client.get resource.pluralize, { perPage: 500 }

      if response.success?
        response_hash = JSON.parse response.body
        response_hash.map { |entity| { 'id' => entity["#{resource}Id"], 'name' => entity['name'] } }
      else
        error_message = JSON.parse(response.body)['codeDescription']
        log "getting lists returned '#{ error_message }' with the code #{ response.status }"
        raise error_message
      end
    end

    def fetch_latest_contacts count = 2
      query = {
        fields: 'contactId,email',
        sort: {
          createdOn: :desc
        },
        page: 0,
        perPage: count
      }

      response = client.get 'contacts', query

      if response.success?
        JSON.parse response.body
      else
        error_message = JSON.parse(response.body)['codeDescription']
        log "fetching contact returned '#{ error_message }' with the code #{ response.status }"
        raise error_message
      end
    end

    def assign_tags contact_id:, tags:
      response = client.post "contacts/#{ contact_id }", { tags: tags }

      if response.success?
        JSON.parse response.body
      else
        error_message = JSON.parse(response.body)['codeDescription']
        log "assign tags returned '#{ error_message }' with the code #{ response.status }"
        raise error_message
      end
    end
  end
end
