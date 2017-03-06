class DiscountCalculator
  attr_reader :discounts

  def initialize(subscription, user = nil)
    @user = user || subscription.payment_method.try(:user)
    @subscription = subscription
    @discounts = subscription.class.defaults[:discounts] || []
    @discounts.sort_by!(&:tier)
  end

  def current_discount
    return 0 if @user.nil? || @subscription.nil?

    discount = discount_for_index(discount_index)
    discount.nil? ? 0 : discount.send(@subscription.schedule)
  end

  private

  def discount_for_index(index)
    return nil if index.nil?

    @discounts.each do |discount|
      return discount if discount.slots.nil? || index < discount.slots
      index -= discount.slots
    end
    nil
  end

  def discount_index
    subs = active_subscriptions.sort_by! { |x| x.site.created_at }
    subs.index(@subscription) || subs.count
  end

  def active_subscriptions
    subscriptions = @user.sites.includes(subscriptions: :payment_method).map(&:current_subscription)
    subscriptions.select! { |s| s.instance_of?(@subscription.class) }
    subscriptions.select! { |s| s.payment_method && s.payment_method.try(:user) == @user }
    subscriptions
  end
end
