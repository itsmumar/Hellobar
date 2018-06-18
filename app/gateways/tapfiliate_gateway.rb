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
  def store_commission bill:
    user = bill.subscription&.credit_card&.user

    return if user&.affiliate_information&.conversion_identifier.blank?

    conversion_identifier = user.affiliate_information.conversion_identifier

    body = {
      conversion_sub_amount: bill.amount,
      comment: commission_comment(bill)
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

  def commission_comment bill
    subscription = bill.subscription

    "Paid Bill##{ bill.id } for #{ subscription.type } (#{ subscription.schedule })"
  end
end
