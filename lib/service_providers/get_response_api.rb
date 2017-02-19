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
            # is required when it comes to tagging
            contacts = fetch_latest_contacts

            contacts.each do |contact|
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

    def redress_tagging
      contacts = contacts_with_tags(10)
      subscribers = @contact_list.subscribers(20)

      contacts.each do |contact|
        found_subscriber = subscribers.map do |subscriber|
          return subscriber if subscriber["email"] == contact["email"]
        end

        if found_subscriber
          subscriber_tags = @contact_list.tags
          contact_tags = contact["tags"].map { |tag| tag["tagId"] }

          unless subscriber_tags.sort == contact_tags.sort
            assign_tags contact_id: contact["contactId"], tags: subscriber_tags
          end
        end
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

    def contacts_with_tags(count = 10)
      contacts = fetch_latest_contacts(count)
      contacts.map do |contact|
        contact["tags"] = contact_details(contact["contactId"])["tags"]
      end

      contacts

      # Comment me
      # contacts = [{"contactId"=>"PMwlAP", "email"=>"suram17022@gmail.com", "tags"=>[{"tagId"=>"pJP5", "name"=>"hellobar", "href"=>"https://api.getresponse.com/v3/tags/pJP5", "color"=>""}, {"tagId"=>"pJub", "name"=>"new_lead", "href"=>"https://api.getresponse.com/v3/tags/pJub", "color"=>""}, {"tagId"=>"pJk7", "name"=>"test_neha", "href"=>"https://api.getresponse.com/v3/tags/pJk7", "color"=>""}]}, {"contactId"=>"PM9yT7", "email"=>"suram20171702@gmail.com", "tags"=>[{"tagId"=>"pJP5", "name"=>"hellobar", "href"=>"https://api.getresponse.com/v3/tags/pJP5", "color"=>""}, {"tagId"=>"pJub", "name"=>"new_lead", "href"=>"https://api.getresponse.com/v3/tags/pJub", "color"=>""}, {"tagId"=>"pJk7", "name"=>"test_neha", "href"=>"https://api.getresponse.com/v3/tags/pJk7", "color"=>""}]}, {"contactId"=>"PMiZSm", "email"=>"suram17021@gmail.com", "tags"=>[{"tagId"=>"pJk7", "name"=>"test_neha", "href"=>"https://api.getresponse.com/v3/tags/pJk7", "color"=>""}]}, {"contactId"=>"PMinwr", "email"=>"suram1702@gmail.com", "tags"=>[{"tagId"=>"pJk7", "name"=>"test_neha", "href"=>"https://api.getresponse.com/v3/tags/pJk7", "color"=>""}]}, {"contactId"=>"PMZbgF", "email"=>"xoishb@gmail.com", "tags"=>[{"tagId"=>"pJP5", "name"=>"hellobar", "href"=>"https://api.getresponse.com/v3/tags/pJP5", "color"=>""}, {"tagId"=>"pJub", "name"=>"new_lead", "href"=>"https://api.getresponse.com/v3/tags/pJub", "color"=>""}, {"tagId"=>"pJk7", "name"=>"test_neha", "href"=>"https://api.getresponse.com/v3/tags/pJk7", "color"=>""}]}, {"contactId"=>"PMZC7r", "email"=>"crossover.hellobar@gmail.com", "tags"=>[{"tagId"=>"pJk7", "name"=>"test_neha", "href"=>"https://api.getresponse.com/v3/tags/pJk7", "color"=>""}]}, {"contactId"=>"PMZFem", "email"=>"hellobarqa@gmail.com", "tags"=>[{"tagId"=>"pJub", "name"=>"new_lead", "href"=>"https://api.getresponse.com/v3/tags/pJub", "color"=>""}]}, {"contactId"=>"PMZ56E", "email"=>"hellobareng@gmail.com", "tags"=>[{"tagId"=>"pJP5", "name"=>"hellobar", "href"=>"https://api.getresponse.com/v3/tags/pJP5", "color"=>""}]}, {"contactId"=>"PQATOL", "email"=>"hellobardev@gmail.com", "tags"=>[{"tagId"=>"pJP5", "name"=>"hellobar", "href"=>"https://api.getresponse.com/v3/tags/pJP5", "color"=>""}]}, {"contactId"=>"PQ5IE5", "email"=>"pawel.goscicki+feb16@crossover.com", "tags"=>[{"tagId"=>"pJP5", "name"=>"hellobar", "href"=>"https://api.getresponse.com/v3/tags/pJP5", "color"=>""}]}]
    end

    def contact_details(contact_id)
      response = client.get "contacts/#{contact_id}"

      if response.success?
        JSON.parse response.body
      else
        error_message = JSON.parse(response.body)['codeDescription']
        log "getting lists returned '#{ error_message }' with the code #{ response.status }"
        raise error_message
      end
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
