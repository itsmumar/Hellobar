class ProfitwellAnalyticsAdapter
  def track(event:, subscription:, previous_subscription:, user:)
    case event
    when :upgraded_subscription, :downgraded_subscription
      subscription_updated subscription, previous_subscription, user
    end
  end

  def tag_users(*)
    # do nothing
  end

  def untag_users(*)
    # do nothing
  end

  private

  def subscription_updated(subscription, previous_subscription, user)
    if previous_subscription
      profitwell.churn_subscription(previous_subscription.id, subscription.created_at)
    else
      profitwell.create_subscription(user, subscription)
    end
  end

  def profitwell
    @profitwell ||= ProfitwellGateway.new
  end
end
