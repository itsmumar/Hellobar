module ServiceProviders
  module Adapters
    class GetResponse < Base
      class RequestError < StandardError; end

      register :get_response

      def initialize(config_source)
        client_settings = {
          url: 'https://api.getresponse.com/v3',
          headers: {
            'X-Auth-Token' => "api-key #{ config_source.api_key }"
          }
        }

        client = Faraday.new(client_settings) do |faraday|
          faraday.request :url_encoded
          faraday.response :logger unless Rails.env.test?
          faraday.adapter Faraday.default_adapter
        end
        super client
      end

      def lists
        response = process_response client.get '/campaigns', perPage: 500
        response.map { |list| { 'id' => list['campaignId'], 'name' => list['name'] } }
      end

      def tags
        response = process_response client.get '/tags', perPage: 500
        response.map { |tag| { 'id' => tag['tagId'], 'name' => tag['name'] } }
      end

      def subscribe(list_id, params, tags: [], cycle_day: nil)
        tags = tags.map { |tag| { tagId: tag } } if tags.present?

        request_body = {
          email: params[:email],
          campaign: {
            campaignId: list_id
          }
        }
        request_body[:name] = params[:name] if params[:name].present?

        request_body.update(dayOfCycle: cycle_day) if cycle_day.present?

        response = process_response client.post '/contacts', request_body
        assign_tags(tags)
        response
      rescue Faraday::TimeoutError
        log 'sync timed out'
      rescue => error
        log "sync raised #{ error }"
      end

      def batch_subscribe(list_id, subscribers)
        subscribers.each do |subscriber|
          subscribe(list_id, subscriber)
        end
      end

      private

      def process_response(response)
        response_hash = JSON.parse response.body
        return response_hash if response.success?

        raise RequestError, response_hash['codeDescription']
      end

      # In GetResponse you cannot assign tags to contacts sent via API,
      # however you can assign tags to existing contacts in the list, so
      # we will tag the two most recently added contacts (we could tag
      # only the most recent one, but there could be some race conditions)
      # This is a little bit of a hack, but it should give us 95% of what
      # is required when it comes to tagging.
      # We add tags only to contacts which are also stored at HelloBar,
      # so that unknown origin contacts at GR won't get tagged by us
      # https://crossover.atlassian.net/browse/XOHB-1397
      def assign_tags(tags)
        return if tags.blank?

        contacts = fetch_latest_contacts(20)
        subscribers = contact_list.subscribers(10)

        find_union(contacts, subscribers).each do |contact|
          process_response client.post "/contacts/#{ contact['contactId'] }", tags: tags
        end
      end

      def fetch_latest_contacts(count = 2)
        query = {
          fields: 'contactId,email',
          sort: {
            createdOn: :desc
          },
          page: 0,
          perPage: count
        }

        process_response client.get '/contacts', query
      end

      def find_union(contacts, subscribers, count = 2)
        found_contacts = []

        contacts.each do |contact|
          subscribers.map do |subscriber|
            found_contacts << contact if subscriber[:email] == contact['email']
          end

          break if found_contacts.count >= count
        end

        found_contacts
      end
    end
  end
end
