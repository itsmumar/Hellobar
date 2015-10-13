class DiscountCalculator
  attr_reader :discounts

  def initialize(discounts, subscription)
    @user = subscription.payment_method.try(:user)
    @subscription = subscription
    @discounts = discounts || []
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
    subs.index(@subscription)
  end

  def active_subscriptions
    subscriptions = @user.sites.includes(subscriptions: :payment_method).map(&:current_subscription)
    subscriptions.select! { |s| s.instance_of?(@subscription.class) }
    subscriptions.select! { |s| s.payment_method && s.payment_method.try(:user) == @user}
    subscriptions
  end
end

# Struct for holding discount information
# Params
# slots - number of subscriptions that this tier can hold
# tier - index of the tier, higher index is applied later
# monthly - amount to discount for a monthly subscriptions
# yearly - amount to discount for a yearly subscriptions
DiscountRange = Struct.new(:slots, :tier, :monthly, :yearly)
