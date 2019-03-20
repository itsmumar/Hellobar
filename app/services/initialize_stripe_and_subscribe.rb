class InitializeStripeAndSubscribe
  DEFAULT_CURRENCY = 'usd'.freeze

  def initialize(params, user, site)
    @stripe_token = params[:stripeToken]
    @user = user
    @customer = nil
    @stripe_subscription = nil
    @site = site
    @plan = params[:plan]
    @schedule = params[:schedule]
    @credit_card = nil
    @old_subscription = site.current_subscription
  end

  def call
    find_or_initialize_customer
    find_or_initialize_credit_card
    subscribe_to_plan
  end

  private

  attr_accessor :user, :stripe_token, :customer, :credit_card, :site, :plan, :old_subscription, :schedule, :stripe_subscription

  def find_or_initialize_credit_card
    card = customer.sources.data.last
    self.credit_card = if stripe_token.blank?
                         CreditCard.where(stripe_id: card.id).first
                       else
                         CreditCard.create(user: user, stripe_id: card.id, month: card.exp_month, year: card.exp_year, brand: card.brand, country: card.country, number: card.last4)
                       end
  end

  def find_or_initialize_customer
    if user.stripe?
      retrieve_customer(user.stripe_customer_id)
    elsif stripe_token.present?
      create_customer
    end
  end

  def create_customer
    self.customer = Stripe::Customer.create(
      email: user.email,
      source: stripe_token
    )
    user.update(stripe_customer_id: customer.id)
  end

  def retrieve_customer(stripe_token)
    self.customer = Stripe::Customer.retrieve(stripe_token)
  end

  def subscribe_to_plan
    if site.current_subscription.free? || site.current_subscription.currently_on_trial?
      self.stripe_subscription = Stripe::Subscription.create(customer: customer.id, plan: stripe_plan_name)
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
    end
    change_subscription
  end

  def stripe_plan_name
    plan + '-' + schedule
  end

  def subscription_class
    Subscription.const_get(plan.capitalize)
  end

  def change_subscription
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
    end
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
