module ServiceProviders
  module Adapters
    class MailChimp < Base
      register :mailchimp

      def self.oauth?
        true
      end

      def initialize(identity)
        client = Gibbon::Request.new(
          api_key: identity.credentials['token'],
          api_endpoint: identity.extra['metadata']['api_endpoint']
        )
        super client
      end

      def lists
        raw_lists.map { |raw_list| raw_list.slice('id', 'name') }
      end

      def subscribe(list_id, params)
        client.lists(list_id).members.create(params)
      end

      private

      def raw_lists
        raw_lists = client.lists.retrieve(params: { count: 100 })['lists']
        raw_lists.presence || []
      end
    end
  end
end
