class BillSerializer < ActiveModel::Serializer
  attributes :amount, :bill_at, :end_date, :status, :is_upgrade, :old_subscription, :site

  def site
    {
      current_subscription: site_serializer.current_subscription,
      display_name: site_serializer.display_name
    }
  end

  def upgrade?
    return true unless object.site.previous_subscription
    Subscription::Comparison.new(object.site.previous_subscription, object.subscription).upgrade?
  end
  alias is_upgrade upgrade?

  def old_subscription
    SubscriptionSerializer.new(object.site.previous_subscription)
  end

  private

  def site_serializer
    SiteSerializer.new(object.site)
  end
end
