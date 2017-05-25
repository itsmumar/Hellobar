module ServiceProviders
  module Adapters
    class IContactForm < Base
      register :icontact

      def self.embed_code?
        true
      end

      def initialize(config_source)
        super VerticalResponse::API::OAuth.new config_source.credentials['token']
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
      rescue VerticalResponse::API::Error => e
        raise e unless e.message == 'Contact already exists.'
      end

      def batch_subscribe(list_id, subscribers)
        contacts = subscribers.map do |subscriber|
          first_name, last_name = subscriber[:name].split(' ', 2)
          params = { email: params[:email] }
          params[:first_name] = first_name if first_name.present?
          params[:last_name] = last_name if last_name.present?
          params
        end

        client.find_list(list_id).create_contacts(contacts)
      rescue VerticalResponse::API::Error => e
        raise e unless e.message == 'Contact already exists.'
      end
    end
  end
end
