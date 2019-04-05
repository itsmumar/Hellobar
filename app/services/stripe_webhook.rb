class StripeWebhook
  CHARGE_FAILED = 'charge.failed'.freeze

  def initialize(event)
    if event.type == 'charge.failed'
      @event_type = event.type
      @event = event
      @customer_id = event.data.object.customer
      @user = User.find_by(stripe_customer_id: customer_id)
      @site = @user.sites.find_by(url: stripe_customer.description)
      @subscription = site.current_subscription
      @bill = site.bills.last
    elsif event.type == 'customer.subscription.deleted'
      @event_type = event.type
      @user = User.find_by(stripe_customer_id: customer_id)
      @site = @user.sites.find_by(url: stripe_customer.description)
    end
  end

  def call
    if @event_type == 'charge.failed'
      failed_charge
    elsif @event_type == 'customer.subscription.deleted'
      cancelled_subscription
    end
  end

  private

  attr_accessor :event_type, :customer_id, :user, :site, :subscription, :bill, :event

  def stripe_customer
    @stripe_customer ||= Stripe::Customer.retrieve(customer_id)
  end


  def failed_charge
    case event_type
    when CHARGE_FAILED
      if bill.created_at > 3.days.ago
        bill.update(status: 'failed')
      else
        create_bill
      end
    end
  end

  def cancelled_subscription
    DowngradeSiteToFree.new(@site).call
  end

  def create_bill
    @bill = Bill.create(subscription: subscription,
                amount: subscription.amount,
                grace_period_allowed: false,
                bill_at: Time.current,
                start_date: Time.current,
                end_date: Time.current,
                status: 'failed',
                source: Bill::STRIPE_SOURCE)
    create_bill_attempt
  end

  def create_bill_attempt
    BillingAttempt.create!(
      bill: bill,
      action: BillingAttempt::CHARGE,
      credit_card: credit_card,
      status:  BillingAttempt::STATE_FAILED,
      response: event.id
    )
  end
end
