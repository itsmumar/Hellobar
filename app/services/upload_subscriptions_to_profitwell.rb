require 'typhoeus'

class UploadSubscriptionsToProfitwell
  attr_reader :typed_out, :wrong, :errored

  ACTIVE = 'active'.freeze
  TRIALING = 'trialing'.freeze

  def initialize
    @typed_out = []
    @wrong = []
    @errored = []

    Typhoeus.before do |request|
      request.on_failure do |response|
        if response.timed_out?
          @typed_out << request
        elsif response.code == 0
          @wrong << request
        else
          @errored << request
        end
      end
    end
  end

  def call
    sites.each do |site|
      subscriptions = site.subscriptions.with_deleted.to_a

      subscriptions.inject(nil) do |prev_subscription, subscription|
        create(subscription)
        churn(prev_subscription, subscription.created_at) if prev_subscription

        subscription
      end
      churn(subscriptions.last, site.deleted_at) if subscriptions.last.deleted? || site.deleted?
    end
  end

  def sites
    Site.unscoped.where(id: Subscription.unscoped.where(id: Bill.paid.non_free.select('subscription_id')).select('site_id'))
  end

  def create(subscription)
    create_request(params(subscription)).run
  end

  def churn(subscription, date)
    churn_request(subscription.id, date).run
  end

  def create_request(params)
    Typhoeus::Request.new(
      'https://api.profitwell.com/v2/subscriptions/',
      method: :post,
      body: params.to_json,
      headers: headers
    )
  end

  def churn_request(id, date)
    Typhoeus::Request.new(
      "https://api.profitwell.com/v2/subscriptions/#{ id }/?effective_date=#{ date.to_i }",
      method: :delete,
      headers: headers
    )
  end

  def params(subscription)
    owner = subscription.site.owners.with_deleted.first
    {
      user_alias: owner.id,
      subscription_alias: subscription.id,
      email: owner.email,
      plan_id: subscription.type,
      plan_interval: subscription.monthly? ? 'month' : 'year',
      plan_currency: 'usd',
      status: subscription.free? ? TRIALING : ACTIVE,
      value: (subscription.amount * 100).to_i,
      effective_date: subscription.created_at.to_i
    }
  end

  def headers
    {
      content_type: 'application/json',
      authorization: Settings.profitwell_api_key
    }
  end

  def user(user)
    JSON.parse(Typhoeus::Request.get("https://api.profitwell.com/v2/users/#{ user.id }/", headers: headers).body)
  end
end
