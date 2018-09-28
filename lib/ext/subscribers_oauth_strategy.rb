require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Subscribers < OmniAuth::Strategies::OAuth2
      # change the class name and the :name option to match your application name
      option :name, 'subscribers'

      option :client_options, \
        site: Settings.subscribers_app_url,
        request_token_path: '/auth/request_token',
        authorize_path:     '/auth/authorize',
        access_token_path:  '/auth/access_token',
        scheme: :query_string

      uid { raw_info['id'] }

      info do
        raw_info
      end

      def raw_info
        @raw_info ||= access_token.get('/me.json').parsed
      end

      # https://github.com/intridea/omniauth-oauth2/issues/81
      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
