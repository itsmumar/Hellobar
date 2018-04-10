module RequestSpecHelper
  def json
    deep_with_indifferent_access(JSON.parse(response.body))
  end

  def api_headers_for_user(user)
    token = JsonWebToken.encode Hash[user_id: user.id]

    Hash['Authorization' => "Bearer #{ token }"]
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
