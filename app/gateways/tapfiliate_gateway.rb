class TapfiliateGateway
  include HTTParty

  base_uri 'https://api.tapfiliate.com/1.6/conversions/'

  # signups tracking
  def store_conversion user:
    return if user.affiliate_information.blank?

    body = {
      visitor_id: user.affiliate_information.visitor_identifier,
      external_id: user.id,
      amount: 0
    }

    post! '/', body
  end

  # paid bill tracking
  def store_commission conversion_identifier:, amount:, comment:
    body = {
      conversion_sub_amount: amount,
      comment: comment
    }

    post! "/#{ conversion_identifier }/commissions/", body
  end

  private

  def post! path, body
    self.class.post path, body: body.to_json, headers: headers
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Api-Key' => Settings.tapfiliate_api_key
    }
  end
end
