module ServiceProviders
  module Adapters
    class MadMimiForm < Base
      register :mad_mimi_form

      def initialize(config_source)
        super MadMimi.new(config_source.credentials['username'], config_source.api_key, raise_exceptions: true)
      end

      def lists
        client.lists.dig('lists', 'list')
      end

      def subscribe(list_id, params)
        options = {}
        options[:name] = params[:name] if name.present?

        client.add_to_list(params[:email], list_id, options)
      end

      def batch_subscribe(list_id, subscribers)
        client.add_users(
          subscribers.map { |subscriber| subscribers.merge(add_list: list_id) }
        )
      end
    end
  end
end
