class TrackSubscriptionChange
  def initialize(user, old_subscription, new_subscription)
    @user = user
    @old_subscription = old_subscription
    @new_subscription = new_subscription
  end

  def call
    return if skip?

    if upgrade?
      track_upgrade
    else
      track_downgrade
    end
  end

  private

  attr_reader :user, :old_subscription, :new_subscription

  def skip?
    return true if new_subscription.free? && old_subscription.nil?
    return true if old_subscription && old_subscription.name == new_subscription.name

    false
  end

  def upgrade?
    old_subscription.nil? || Subscription::Comparison.new(old_subscription, new_subscription).upgrade?
  end

  def track_upgrade
    TrackEvent.new(:upgraded_subscription, event_params).call
  end

  def track_downgrade
    TrackEvent.new(:downgraded_subscription, event_params).call
  end

  def event_params
    {
      subscription: new_subscription,
      previous_subscription: old_subscription,
      user: user
    }
  end
end
