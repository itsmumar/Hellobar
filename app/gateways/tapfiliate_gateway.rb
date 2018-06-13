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

    result = post! '/', body

    save_conversion_identifier user, result
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

  def save_conversion_identifier user, result
    if result.success?
      user.affiliate_information.update conversion_identifier: result['id']
    else
      Rails.logger.info "Tapfiliate error: #{ result['errors'] }"
    end
  end

  def commission_comment bill
    subscription = bill.subscription
    site = subscription.site
    user = subscription.credit_card.user

    "Paid Bill##{ bill.id } for #{ subscription.type } (#{ subscription.schedule }) for User##{ user.id } Site##{ site.id }"
  end
end
