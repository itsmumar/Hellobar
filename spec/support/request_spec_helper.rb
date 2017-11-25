module RequestSpecHelper
  def json
    JSON.parse(response.body).with_indifferent_access
  end

  def api_headers_for_site_user site, user
    token = JsonWebToken.encode Hash[site_id: site.id, user_id: user.id]

    Hash['Authorization' => "Bearer #{ token }"]
  end
end
