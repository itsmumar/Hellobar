HTTPI.log = false

module ServiceProviders
  module Adapters
    class ActiveCampaign < Api
      register :active_campaign

      def initialize(config_source)
        super ::ActiveCampaign::Client.new(
          api_endpoint: 'https://' + config_source.extra['app_url'] + '/admin/api.php',
          api_key: config_source.api_key
        )
      end

      def lists
        response = client.list_list ids: 'all'
        raise response['result_message'] unless response['result_code'] == 1
        response['results'].map { |raw_list| raw_list.slice('id', 'name') }
      end

      def subscribe(list_id, contact)
        base = { "p[#{ list_id }]" => list_id }
        response = client.contact_sync(base.merge(contact))
        raise response['result_message'] unless response['result_code'] == 1
      end
    end
  end
end
