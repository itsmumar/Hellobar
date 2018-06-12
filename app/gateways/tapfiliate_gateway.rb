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

    result = post! body

    save_conversion_identifier user, result
  end

  private

  def post! body
    self.class.post '/', body: body.to_json, headers: headers
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Api-Key' => Settings.tapfiliate_api_key
    }
  end

  def save_conversion_identifier user, result
    if result.success?
      user.affiliate_information.update conversion_identifier: result['id']
    else
      Rails.logger.info "Tapfiliate error: #{ result['errors'] }"
    end
  end
end
