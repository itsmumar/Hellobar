class ProfitwellGateway
  include HTTParty

  PLAN_CURRENCY = 'usd'.freeze
  ACTIVE = 'active'.freeze
  TRIALING = 'trialing'.freeze

  base_uri 'https://api.profitwell.com/v2/'

  def create_subscription(owner, subscription)
    body = {
      user_alias: owner.id,
      subscription_alias: subscription.site_id,
      email: owner.email,
      plan_id: subscription.type,
      plan_interval: subscription.monthly? ? 'month' : 'year',
      plan_currency: PLAN_CURRENCY,
      status: subscription.free? ? TRIALING : ACTIVE,
      value: (subscription.amount * 100).to_i, # in cents
      effective_date: subscription.created_at.to_i
    }

    post! '/subscriptions/', body
  end

  def churn_subscription(subscription_id, date)
    delete! "/subscriptions/#{ subscription_id }/?effective_date=#{ date.to_i }"
  end

  private

  def post! path, body
    self.class.post path, body: body.to_json, headers: headers
  end

  def delete! path
    self.class.delete path, headers: headers
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => Settings.profitwell_api_key
    }
  end
end
