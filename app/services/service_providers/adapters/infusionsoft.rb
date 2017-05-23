module ServiceProviders
  module Adapters
    class Infusionsoft < Base
      def initialize(config_source)
        Infusionsoft.configure do |config|
          config.api_url = config_source.extra['app_url']
          config.api_key = config_source.api_key
        end
      end

      def tags
        Infusionsoft
          .data_query('ContactGroup', 1000, 0, {}, %w[GroupName Id])
          .map { |result| { 'name' => result['GroupName'], 'id' => result['Id'] } }
          .sort_by { |result| result['name'] }
      end

      def subscribe(_list_id, params)
        data = { Email: params[:email] }

        first_name, last_name = name.split(' ', 2)

        data[:FirstName] = first_name if first_name.present?
        data[:LastName] = last_name if last_name.present?

        infusionsoft_user_id = Infusionsoft.contact_add_with_dup_check(data, :Email)

        contact_list.tags.each do |tag_id|
          Infusionsoft.contact_add_to_group(infusionsoft_user_id, tag_id)
        end
      end

      def batch_subscribe(list_id, subscribers)
        subscribers.each do |subscriber|
          subscribe(list_id, subscriber)
        end
      end
    end
  end
end
