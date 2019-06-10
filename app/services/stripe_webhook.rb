class StripeWebhook
  CUSTOMER_SUBSCRIPTION_DELETED = 'customer.subscription.deleted'.freeze
  PAID = 'paid'.freeze
  FAILED = 'failed'.freeze
  SUCCEEDED_CHARGE_TYPES = ['invoice.payment_succeeded', 'charge.succeeded'].freeze
  FAILED_CHARGE_TYPES = ['invoice.payment_failed', 'charge.failed'].freeze

  def initialize(event)
    if SUCCEEDED_CHARGE_TYPES.include?(event.type) || FAILED_CHARGE_TYPES.include?(event.type)
      @event_type = event.type
      @event = event
      @customer_id = event.data.object.customer
      @invoice_id = event.data.object.invoice
      @site = Site.find_by(url: site_url)
      @subscription = site.current_subscription
      @bill = site.bills.last
    elsif event.type == CUSTOMER_SUBSCRIPTION_DELETED
      @stripe_subscription_id = event.data.object.id
      @event_type = event.type
      @site = Site.find_by(url: site_url)
    end
  end

  def call
    if FAILED_CHARGE_TYPES.include?(@event_type)
      failed_charge
    elsif SUCCEEDED_CHARGE_TYPES.include?(@event_type)
      succeed_charge
    elsif @event_type == CUSTOMER_SUBSCRIPTION_DELETED
      cancelled_subscription
    end
  end

  private

  attr_accessor :event_type, :customer_id, :site, :subscription, :bill, :event, :stripe_subscription_id, :invoice_id

  def stripe_customer
    @stripe_customer ||= Stripe::Customer.retrieve(customer_id)
  end

  def stripe_subscription
    if FAILED_CHARGE_TYPES.include?(@event_type)
      @stripe_subscription ||= Stripe::Subscription.retrieve(stripe_invoice.subscription)
    elsif @event_type == CUSTOMER_SUBSCRIPTION_DELETED
      @stripe_subscription ||= Stripe::Subscription.retrieve(stripe_subscription_id)
    end
  end

  def stripe_invoice
    @stripe_invoice ||= Stripe::Invoice.retrieve(invoice_id)
  end

  def site_url
    @site_url ||= stripe_subscription.metadata.site
  end

  def succeed_charge
    bill.update(status: PAID) if bill && bill.status == FAILED
    # notify_admins
  end

  def failed_charge
    if bill.created_at > 3.days.ago
      bill.update(status: FAILED)
    else
      create_bill
    end
    # notify_admins
  end

  # def notify_admins(user, message)
  # end

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
                status: FAILED,
                source: Bill::STRIPE_SOURCE)
    create_bill_attempt
  end

  def create_bill_attempt
    BillingAttempt.create!(
      bill: bill,
      action: BillingAttempt::CHARGE,
      credit_card: credit_card,
      status: BillingAttempt::STATE_FAILED,
      response: event.id
    )
  end
end
