module ServiceProviders
  module Adapters
    class ConvertKit < FaradayClient
      register :convert_kit

      config.error_path = 'error'

      def initialize(config_source)
        super 'https://api.convertkit.com/v3', params: { api_secret: config_source.api_key }
      end

      def lists
        response = process_response client.get '/forms'
        response['forms'].map { |form| form.slice('id', 'name') }
      end

      def tags
        response = process_response client.get '/tags'
        response['tags'].map { |tag| tag.slice('id', 'name') }
      end

      def subscribe(form_id, params)
        body = {
          email: params[:email],
          tags: params[:tags].join(',')
        }

        if params[:name].present?
          first_name, last_name = params[:name].split(' ', 2)
          body[:first_name] = first_name
          body[:fields] = { last_name: last_name } if last_name.present?
        end

        process_response client.post "/forms/#{ form_id }/subscribe", body: body
      end
    end
  end
end
