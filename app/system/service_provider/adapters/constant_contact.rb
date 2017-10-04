module ServiceProvider::Adapters
  class ConstantContact < FaradayClient
    configure do
      config.app_key = Settings.identity_providers['constantcontact']['app_key']
      config.app_secret = Settings.identity_providers['constantcontact']['app_secret']
      config.oauth = true
    end

    def initialize(identity)
      headers = { authorization: "Bearer #{ identity.credentials['token'] }" }
      params = { api_key: config.app_key }
      super identity, 'https://api.constantcontact.com/v2', request: :json, params: params, headers: headers
    end

    def lists
      response = process_response client.get('lists')
      response.map { |list| list.slice('id', 'name') }
    end

    def subscribe(list_id, params)
      data = {
        email_addresses: [{ email_address: params[:email] }],
        lists: [{ id: list_id }]
      }
      data[:first_name], data[:last_name] = params[:name].split(' ') if params[:name].present?

      add_contact list_id, params, data
    end

    private

    def find_contact(email)
      response = process_response(client.get('contacts', email: email))
      response.dig 'results', 0
    end

    def add_contact(list_id, params, data)
      client.post 'contacts' do |req|
        req.params.update action_by: 'ACTION_BY_VISITOR' if params[:double_optin]
        req.body = data.to_json
      end
    rescue Faraday::Conflict
      contact = find_contact(params[:email])
      return unless contact
      contact['lists'] << { id: list_id }
      update_contact params, contact
    rescue ServiceProvider::InvalidSubscriberError => e
      # if the email is not valid, CC will raise an exception and we end up here
      # when this happens, just return true and continue
      return if e.inspect =~ /not a valid email address/
      raise e unless e.inspect =~ /not be opted in using/

      # sometimes constant contact doesn't allow you to skip double opt-in, and lets you know by exploding
      # if that happens, try adding contact again WITH double opt-in
      subscribe(list_id, params.merge(double_optin: true)) unless params[:double_optin]
    end

    def update_contact(params, data)
      client.put "contacts/#{ data['id'] }" do |req|
        req.params.update action_by: 'ACTION_BY_VISITOR' if params[:double_optin]
        req.body = data.to_json
      end
    rescue Faraday::Conflict # rubocop:disable Lint/HandleExceptions
      # do nothing
    end
  end
end
