module ServiceProviders
  module Adapters
    class Infusionsoft < Base
      register :infusionsoft

      def initialize(identity)
        super ::Infusionsoft::Client.new(
          api_url: identity.extra['app_url'],
          api_key: identity.api_key,
          api_logger: Logger.new(nil)
        )
      end

      def tags
        client
          .data_query('ContactGroup', 1000, 0, {}, %w[GroupName Id])
          .map { |result| { 'name' => result['GroupName'], 'id' => result['Id'] } }
          .sort_by { |result| result['name'] }
      end

      def subscribe(_list_id, params)
        data = { Email: params[:email] }

        first_name, last_name = params[:name].split(' ', 2) if params[:name].present?

        data[:FirstName] = first_name if first_name.present?
        data[:LastName] = last_name if last_name.present?

        infusionsoft_user_id = client.contact_add_with_dup_check(data, :EmailAndName)

        params.fetch(:tags, []).each do |tag_id|
          client.contact_add_to_group(infusionsoft_user_id, tag_id)
        end
      end
    end
  end
end
