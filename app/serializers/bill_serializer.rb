class BillSerializer < ActiveModel::Serializer
  attributes :amount, :bill_at, :end_date, :status, :is_upgrade, :old_subscription, :site
  attributes :subscription_name, :subscription_schedule

  def subscription_name
    object.subscription.name
  end

  def subscription_schedule
    object.subscription.schedule
  end

  def site
    SiteSerializer.new(object.site).as_json
  end

  def upgrade?
    return false unless scope[:action] == 'changed'
    return true unless object.site.previous_subscription

    Subscription::Comparison.new(object.site.previous_subscription, object.subscription).upgrade?
  end

  alias is_upgrade upgrade?

  def old_subscription
    return unless object.site.previous_subscription

    SubscriptionSerializer.new(object.site.previous_subscription).as_json
  end

  def action
    scope[:action]
  end
end
