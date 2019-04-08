class StripeWebhook
  CHARGE_FAILED = 'charge.failed'.freeze
  CUSTOMER_SUBSCRIPTION_DELETED = 'customer.subscription.deleted'.freeze

  def initialize(event)
    if event.type == CHARGE_FAILED
      @event_type = event.type
      @event = event
      @customer_id = event.data.object.customer
      @invoice_id = event.data.object.invoice
      @user = User.find_by(stripe_customer_id: customer_id)
      @site = @user.sites.find_by(url: site_url)
      @subscription = site.current_subscription
      @bill = site.bills.last
    elsif event.type == CUSTOMER_SUBSCRIPTION_DELETED
      @stripe_subscription_id = event.data.object.id
      @event_type = event.type
      @user = User.find_by(stripe_customer_id: customer_id)
      @site = @user.sites.find_by(url: site_url)
    end
  end

  def call
    if @event_type == CHARGE_FAILED
      failed_charge
    elsif @event_type == CUSTOMER_SUBSCRIPTION_DELETED
      cancelled_subscription
    end
  end

  private

  attr_accessor :event_type, :customer_id, :user, :site, :subscription, :bill, :event, :stripe_subscription_id, :invoice_id

  def stripe_customer
    @stripe_customer ||= Stripe::Customer.retrieve(customer_id)
  end

  def stripe_subscription
    if @event_type == CHARGE_FAILED
      @stripe_subscription ||= Stripe::Subscription.retrieve(stripe_invoice.subscription)
    elsif @event_type == CUSTOMER_SUBSCRIPTION_DELETED
      @stripe_subscription ||= Stripe::Subscription.retrieve(stripe_subscription_id)
    end
  end

  def stripe_invoice
    @stripe_invoice ||= Stripe::Invoice.retrieve(invoice_id)
  end

  def site_url
    @site_url = stripe_subscription.metadata.site
  end

  def failed_charge
    if bill.created_at > 3.days.ago
      bill.update(status: 'failed')
    else
      create_bill
    end
    # notify_admins
  end

  # def notify_admins
  #
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
