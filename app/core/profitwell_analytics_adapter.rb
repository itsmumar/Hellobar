class ProfitwellAnalyticsAdapter
  def track(event:, subscription:, previous_subscription:, user:)
    case event
    when :upgraded_subscription
      subscription_upgraded subscription, previous_subscription, user
    when :downgraded_subscription
      subscription_downgraded subscription
    end
  end

  def tag_users(*)
    # do nothing
  end

  def untag_users(*)
    # do nothing
  end

  private

  def subscription_upgraded(subscription, previous_subscription, user)
    if previous_subscription
      profitwell.update_subscription(subscription)
    else
      profitwell.create_subscription(user, subscription)
    end
  end

  def subscription_downgraded(subscription)
    if subscription.free?
      profitwell.churn_subscription(subscription.site_id, subscription.created_at)
    else
      profitwell.update_subscription(subscription)
    end
  end

  def profitwell
    @profitwell ||= ProfitwellGateway.new
  end
end
