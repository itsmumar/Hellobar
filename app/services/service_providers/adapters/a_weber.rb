require 'aweber'

module ServiceProviders
  module Adapters
    class AWeber < Base
      register :aweber

      def initialize(config_source)
        oauth = ::AWeber::OAuth.new(config.aweber.consumer_key, config.aweber.consumer_secret)
        oauth.authorize_with_access(config_source.credentials['token'], config_source.credentials['secret'])
        super ::AWeber::Base.new(oauth)
      end

      def lists
        client.account.lists.map { |_key, raw_list| { 'id' => raw_list.id, 'name' => raw_list.name } }
      end

      def subscribe(list_id, params)
        client.account.lists[list_id.to_i].subscribers.create(params.stringify_keys)
      end

      def batch_subscribe(list_id, subscribers)
        subscribers.each do |subscriber|
          subscribe list_id, subscriber
        end
      end
    end
  end
end
