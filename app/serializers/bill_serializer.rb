class BillSerializer < ActiveModel::Serializer
  attributes :amount, :bill_at, :end_date, :status, :is_upgrade, :old_subscription, :site

  def site
    SiteSerializer.new(object.site)
  end

  def upgrade?
    return true unless object.site.previous_subscription
    Subscription::Comparison.new(object.site.previous_subscription, object.subscription).upgrade?
  end
  alias is_upgrade upgrade?

  def old_subscription
    SubscriptionSerializer.new(object.site.previous_subscription)
  end
end
