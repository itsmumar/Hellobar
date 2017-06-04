module ServiceProviders
  module Adapters
    class AWeber < Base
      register :aweber

      def initialize(identity)
        oauth = ::AWeber::OAuth.new(config.consumer_key, config.consumer_secret)
        oauth.authorize_with_access(identity.credentials['token'], identity.credentials['secret'])
        super ::AWeber::Base.new(oauth)
      end

      def lists
        client.account.lists.map { |_key, raw_list| { 'id' => raw_list.id, 'name' => raw_list.name } }
      end

      def subscribe(list_id, params)
        params = params.stringify_keys.slice('tags', 'email', 'name')
        params['tags'] = params['tags'].to_json if params['tags'].present?

        client.account.lists[list_id.to_i].subscribers.create params
      end
    end
  end
end
