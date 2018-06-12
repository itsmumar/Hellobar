class TapfiliateGateway
  include HTTParty

  base_uri 'https://api.tapfiliate.com/1.6/conversions/'

  # signups tracking
  def store_conversion user:
    body = {
      visitor_id: user.affiliate_information.visitor_identifier,
      external_id: user.id,
      amount: 0
    }

    self.class.post '/', body: body.to_json, headers: headers
  end

  private

  def headers
    {
      'Content-Type' => 'application/json',
      'Api-Key' => Settings.tapfiliate_api_key
    }
  end
end
