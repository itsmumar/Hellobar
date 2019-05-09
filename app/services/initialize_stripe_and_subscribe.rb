class InitializeStripeAndSubscribe
  DEFAULT_CURRENCY = 'usd'.freeze
  PAID_STATUS = 'paid'.freeze

  def initialize(params, user, site)
    @stripe_token = params[:stripeToken]
    @user = user
    @customer = nil
    @stripe_subscription = nil
    @site = site
    @plan = params[:plan]
    @schedule = params[:schedule]
    @credit_card = nil
    @card = nil
    @old_subscription = site.current_subscription if site.present?
    @discount_code = params[:discount_code]
  end

  def call
    find_or_initialize_customer
    find_or_initialize_credit_card
    subscribe_to_plan if plan && plan != 'free'
    credit_card
  end

  private

  attr_accessor :user, :stripe_token, :customer, :credit_card, :site, :plan, :old_subscription, :schedule, :stripe_subscription, :bill, :card, :discount_code

  def find_or_initialize_credit_card
    self.credit_card = if stripe_token.blank?
                         user.credit_cards.last
                       else
                         CreditCard.create(user: user, stripe_id: card.id, month: card.exp_month, year: card.exp_year, brand: card.brand, country: card.country, number: card.last4)
                       end
    site.current_subscription.update(credit_card_id: credit_card.id) if site.try(:current_subscription)
  end

  def find_or_initialize_customer
    if user.stripe?
      retrieve_customer(user.stripe_customer_id)
      initialize_stripe_card if stripe_token.present?
    elsif stripe_token.present?
      create_customer
    end
  end

  def initialize_stripe_card
    self.card = customer.sources.create(source: stripe_token)
    Stripe::Customer.update(customer.id, default_source: card.id)
  end

  def create_customer
    self.customer = Stripe::Customer.create(
      email: user.email,
      source: stripe_token
    )
    user.update(stripe_customer_id: customer.id)
    self.card = customer.sources.data.last
  end

  def retrieve_customer(stripe_token)
    self.customer = Stripe::Customer.retrieve(stripe_token)
  end

  def subscribe_to_plan
    if site.current_subscription.free? || site.current_subscription.currently_on_trial?
      self.stripe_subscription = Stripe::Subscription.create(customer: customer.id,
                                                             plan: stripe_plan_name,
                                                             coupon: discount_code,
                                                             metadata: meta_data)
      change_subscription_and_create_bill
    else
      self.stripe_subscription = Stripe::Subscription.retrieve(old_subscription.stripe_subscription_id)
      Stripe::Subscription.update(
        stripe_subscription.id,
        cancel_at_period_end: false,
        items: [
          {
            id: stripe_subscription.items.data[0].id,
            plan: stripe_plan_name
          }
        ]
      )
      change_subscription
    end
  end

  def meta_data
    { site: site.url }
  end

  def stripe_plan_name
    plan + '-' + schedule
  end

  def subscription_class
    Subscription.const_get(plan.capitalize)
  end

  def change_subscription
    Subscription.transaction do
      subscription = create_subscription
      track_subscription_change(subscription)
    end
  end

  def change_subscription_and_create_bill
    cancel_subscription_if_it_is_free
    create_subscription_and_pay_bill
  end

  def cancel_subscription_if_it_is_free
    return if !old_subscription || old_subscription.paid?
    old_subscription.bills.free.each(&:void!)
  end

  def create_subscription_and_pay_bill
    Subscription.transaction do
      subscription = create_subscription
      track_subscription_change(subscription)
      create_bill(subscription)
    end
  end

  def invoice_amount
    invoice = Stripe::Invoice.all(customer: customer.id)
    amount = invoice.data.first.amount_paid
    format('%.2f', amount.to_i / 100.0)
  end

  def invoice_id
    invoice = Stripe::Invoice.all(customer: customer.id)
    invoice.data.first.id
  end

  def create_bill(subscription)
    @bill = Bill.create(subscription: subscription,
             amount: discount_code.present? ? invoice_amount : subscription.amount,
             grace_period_allowed: false,
             bill_at: Time.current + subscription.period,
             start_date: Time.current,
             end_date: Time.current + subscription.period,
             status: 'paid',
             source: Bill::STRIPE_SOURCE,
             stripe_invoice_id: invoice_id)
    create_bill_attempt
  end

  def create_bill_attempt
    BillingAttempt.create!(
      bill: bill,
      action: BillingAttempt::CHARGE,
      credit_card: credit_card,
      status: BillingAttempt::SUCCESSFUL,
      response: customer.id
    )
  end

  def create_subscription
    subscription_class.create!(
      site: site,
      credit_card: credit_card,
      schedule: schedule,
      stripe_subscription_id: stripe_subscription.id
    )
  end

  def track_subscription_change(subscription)
    return unless subscription&.persisted?

    props = {
      to_subscription: subscription.values[:name],
      to_schedule: subscription.schedule
    }

    if old_subscription
      props[:from_subscription] = old_subscription.values[:name]
      props[:from_schedule] = old_subscription.schedule
    end
    TrackSubscriptionChange.new(credit_card&.user || site.owners.first, old_subscription, subscription).call
  end
end
