class StripeWebhook
  CHARGE_FAILED = 'charge.failed'.freeze

  def initialize(event)
    @event_type = event.type
    @customer_id = event.data.object.customer
    @user = User.find_by(stripe_customer_id: customer_id)
    @site = user.sites.find_by(url: stripe_customer.description)
    @subscription = site.current_subscription
    @bill = site.bills.last
  end

  def call
    case event_type
    when CHARGE_FAILED
      if bill.created_at > 3.days.ago
        bill.update(status: 'failed')
      else
        create_bill
      end
    end
  end

  private

  attr_accessor :event_type, :customer_id, :user, :site, :subscription, :bill

  def stripe_customer
    @stripe_customer ||= Stripe::Customer.retrieve(customer_id)
  end

  def create_bill
    Bill.create(subscription: subscription,
                amount: subscription.amount,
                grace_period_allowed: false,
                bill_at: Time.current,
                start_date: Time.current,
                end_date: Time.current,
                status: 'failed',
                source: STRIPE_SOURCE)
  end
end
