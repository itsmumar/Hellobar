module RequestSpecHelper
  def json
    deep_with_indifferent_access(JSON.parse(response.body))
  end

  def api_headers_for_user(user)
    token = JsonWebToken.encode Hash[user_id: user.id]

    Hash['Authorization' => "Bearer #{ token }"]
  end

  def create_oauth_token(user, scopes:)
    application = Doorkeeper::Application.create!(name: 'App', redirect_uri: 'https://app.con/auth/callback')
    Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, scopes: scopes).token
  end

  private

  def deep_with_indifferent_access(data)
    case data
    when Hash
      data.with_indifferent_access
    when Array
      data.map { |item| deep_with_indifferent_access(item) }
    end
  end
end
