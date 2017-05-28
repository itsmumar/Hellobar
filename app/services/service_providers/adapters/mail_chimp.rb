module ServiceProviders
  module Adapters
    class MailChimp < Base
      register :mailchimp

      def initialize(identity)
        super Gibbon::Request.new(
          api_key: identity.credentials['token'],
          api_endpoint: identity.extra['metadata']['api_endpoint']
        )
      end

      def lists
        raw_lists.map { |raw_list| raw_list.slice('id', 'name') }
      end

      def subscribe(list_id, params)
        client.lists(list_id).members.create body: prepare_params(params)
      end

      def batch_subscribe(list_id, subscribers, double_optin = true)
        operations = prepare_batch_request(list_id, subscribers, double_optin)
        client.batches.create(body: { operations: operations })
      end

      private

      def raw_lists
        raw_lists = client.lists.retrieve(params: { count: 100 })['lists']
        raw_lists.presence || []
      end

      def prepare_batch_request(list_id, subscribers, double_optin = true)
        subscribers.map do |subscriber|
          {
            method: 'POST',
            path: "lists/#{ list_id }/members",
            body: prepare_params(subscriber, double_optin).to_json
          }
        end
      end

      def prepare_params(subscriber, double_optin = true)
        email, name = subscriber.values_at(:email, :name)

        { email_address: email }.tap do |body|
          body[:status] = double_optin ? 'pending' : 'subscribed'

          if name.present?
            first_name, last_name = name.split(' ', 2)
            body[:merge_fields] = {}
            body[:merge_fields][:FNAME] = first_name if first_name.present?
            body[:merge_fields][:LNAME] = last_name if last_name.present?
          end
        end
      end
    end
  end
end
