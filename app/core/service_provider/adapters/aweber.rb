module ServiceProvider::Adapters
  class Aweber < Base
    configure do |config|
      config.app_id = Settings.identity_providers['aweber']['app_id']
      config.consumer_key = Settings.identity_providers['aweber']['consumer_key']
      config.consumer_secret = Settings.identity_providers['aweber']['consumer_secret']
      config.oauth = true
    end

    rescue_from AWeber::CreationError, with: :handle_error

    def initialize(identity)
      oauth = ::AWeber::OAuth.new(config.consumer_key, config.consumer_secret)
      oauth.authorize_with_access(identity.credentials['token'], identity.credentials['secret'])
      super identity, ::AWeber::Base.new(oauth)
    end

    def lists
      client.account.lists.map { |_key, raw_list| { 'id' => raw_list.id, 'name' => raw_list.name } }
    end

    def subscribe(list_id, params)
      params = params.stringify_keys.slice('tags', 'email', 'name')
      params['tags'] = params['tags'].to_json if params['tags'].present?

      client.account.lists[list_id.to_i].subscribers.create params
    end

    private

    def handle_error(e)
      notify_user_about_unauthorized_error if e.message =~ /Invalid consumer key or access token key/
      ignore_error e
    end
  end
end
