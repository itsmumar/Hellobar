module OmniAuth
  module Strategies
    class Drip < OmniAuth::Strategies::OAuth2
      option :name, 'drip'
      option :client_options, {
        :site => 'https://www.getdrip.com',
        :authorize_url => '/oauth/authorize',
        :token_url => '/oauth/token'
      }
    end
  end
end

OmniAuth.config.add_camelization 'createsend', 'CreateSend'
