module ServiceProviders
  module Adapters
    class VerticalResponse < Base
      register :verticalresponse

      def initialize(identity)
        super ::VerticalResponse::API::OAuth.new identity.credentials['token']
      end

      def lists
        client.lists.select { |list| list.response.success? }.map do |list|
          { 'id' => list.id, 'name' => list.response.attributes['name'] }
        end
      end

      def subscribe(list_id, params)
        options = { email: params[:email] }

        if params[:name].present?
          first_name, last_name = params[:name].split(' ', 2)
          options[:first_name] = first_name if first_name.present?
          options[:last_name] = last_name if last_name.present?
        end

        client.find_list(list_id).create_contact(options)
      rescue ::VerticalResponse::API::Error => e
        raise e unless e.message == 'Contact already exists.'
      end

      def batch_subscribe(list_id, subscribers, double_optin: nil) # rubocop:disable Lint/UnusedMethodArgument
        contacts = subscribers.map do |subscriber|
          first_name, last_name = subscriber.fetch(:name, '').split(' ', 2)
          params = { email: subscriber[:email] }
          params[:first_name] = first_name if first_name.present?
          params[:last_name] = last_name if last_name.present?
          params
        end

        client.find_list(list_id).create_contacts(contacts)
      rescue ::VerticalResponse::API::Error => e
        raise e unless e.message == 'Contact already exists.'
      end
    end
  end
end
