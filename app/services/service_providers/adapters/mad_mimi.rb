module ServiceProviders
  module Adapters
    class MadMimi < Base
      register :mad_mimi

      def initialize(config_source)
        super ::MadMimi.new(config_source.credentials['username'], config_source.api_key, raise_exceptions: true)
      end

      def lists
        client.lists.dig('lists', 'list').map { |list| list.slice('id', 'name') }
      end

      def subscribe(list_id, params)
        options = {}
        options[:name] = params[:name] if params[:name].present?

        client.add_to_list(params[:email], list_id, options)
      end

      def batch_subscribe(list_id, subscribers)
        client.add_users(
          subscribers.map { |subscriber| subscriber.merge(add_list: list_id) }
        )
      end
    end
  end
end
