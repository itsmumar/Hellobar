module RequestSpecHelper
  def json
    JSON.parse(response.body).with_indifferent_access
  end

  def api_headers_for_user(user)
    token = JsonWebToken.encode Hash[user_id: user.id]

    Hash['Authorization' => "Bearer #{ token }"]
  end
end
