require 'sinatra/base'
require 'capybara_discoball'

# Define "fake" ip-api.com geolocation service (which sends hardcoded data)
class FakeOAuthClient < Sinatra::Base
  CLIENT_ID = 'fake_client_id'.freeze
  CLIENT_SECRET = 'fake_client_secret'.freeze

  enable :sessions

  def provider_url
    server = Capybara.current_session.server
    "http://#{ server.host }:#{ server.port }"
  end

  def root_url
    request.base_url
  end

  def oauth_callback_url
    "#{ root_url }/oauth/callback"
  end

  def oauth_client
    @oauth_client ||= OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, site: provider_url)
  end

  get '/oauth/callback' do
    token = oauth_client.auth_code.get_token(params[:code], redirect_uri: oauth_callback_url)
    session['access_token'] = token.token
    redirect root_url
  end

  get '/' do
    if session['access_token']
      token = OAuth2::AccessToken.new(oauth_client, session['access_token'])
      user = JSON.parse(token.get('/api/external/me').body).symbolize_keys

      "current_user: #{ user[:email] }"
    else
      redirect oauth_client.auth_code.authorize_url(redirect_uri: oauth_callback_url)
    end
  end
end
