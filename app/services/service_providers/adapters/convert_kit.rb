module ServiceProviders
  module Adapters
    class ConvertKit < Base
      class RequestError < StandardError; end

      register :convert_kit

      def initialize(config_source)
        client = Faraday.new(url: 'https://api.convertkit.com/v3') do |faraday|
          faraday.request :url_encoded
          faraday.response :logger unless Rails.env.test?
          faraday.adapter Faraday.default_adapter
          faraday.params = { api_secret: config_source.api_key }
        end

        super client
      end

      def lists
        response = process_response client.get '/forms'
        response['forms'].map { |form| form.slice('id', 'name') }
      end

      def tags
        response = process_response client.get '/tags'
        response['tags'].map { |tag| tag.slice('id', 'name') }
      end

      def subscribe(form_id, params, tags: [])
        body = {
          email: params[:email],
          tags: tags.join(',')
        }

        if params[:name].present?
          first_name, last_name = name.split(' ', 2)
          body[:first_name] = first_name
          body[:fields] = { last_name: last_name } if last_name.present?
        end

        process_response client.post "/forms/#{ form_id }/subscribe", body: body
      end

      def batch_subscribe(form_id, subscribers)
        subscribers.each do |subscriber|
          subscribe(form_id, subscriber)
        end
      end

      private

      def process_response(response)
        response_hash = JSON.parse response.body
        return response_hash if response.success?

        raise RequestError, response_hash['error']
      end
    end
  end
end
