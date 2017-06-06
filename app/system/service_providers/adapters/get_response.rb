module ServiceProviders
  module Adapters
    class GetResponse < FaradayClient
      configure do |config|
        config.requires_api_key = true
      end

      def initialize(identity)
        super 'https://api.getresponse.com/v3', headers: { 'X-Auth-Token' => "api-key #{ identity.api_key }" }
      end

      def lists
        response = process_response client.get 'campaigns', perPage: 500
        response.map { |list| { 'id' => list['campaignId'], 'name' => list['name'] } }
      end

      def tags
        response = process_response client.get 'tags', perPage: 500
        response.map { |tag| { 'id' => tag['tagId'], 'name' => tag['name'] } }
      end

      def subscribe(list_id, params, cycle_day: nil)
        request_body = {
          email: params[:email],
          campaign: {
            campaignId: list_id
          }
        }
        request_body[:name] = params[:name] if params[:name].present?

        request_body.update(dayOfCycle: cycle_day) if cycle_day.present?

        process_response client.post 'contacts', request_body
      end

      # In GetResponse you cannot assign tags to contacts sent via API,
      # however you can assign tags to existing contacts in the list, so
      # we will tag the twenty most recently added contacts (we could tag
      # only the most recent one, but there could be some race conditions)
      # This is a little bit of a hack, but it should give us 95% of what
      # is required when it comes to tagging.
      # We add tags only to contacts which are also stored at HelloBar,
      # so that unknown origin contacts at GR won't get tagged by us
      # https://crossover.atlassian.net/browse/XOHB-1397
      def assign_tags(contact_list)
        tags = contact_list.tags.map { |tag| { tagId: tag } } if contact_list.tags.present?
        return if tags.blank?

        contacts = fetch_latest_contacts(20)
        subscribers = contact_list.subscribers(10)

        find_union(contacts, subscribers).each do |contact|
          process_response client.post "contacts/#{ contact['contactId'] }", tags: tags
        end
      end

      private

      def fetch_latest_contacts(count = 20)
        query = {
          fields: 'contactId,email',
          sort: {
            createdOn: :desc
          },
          page: 0,
          perPage: count
        }

        process_response client.get 'contacts', query
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
