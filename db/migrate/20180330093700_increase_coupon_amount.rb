class IncreaseCouponAmount < ActiveRecord::Migration
  def up
    Coupon.promotional.update amount: Subscription::Growth.defaults[:monthly_amount]
  end

  def down
    Coupon.promotional.update amount: Subscription::Pro.defaults[:monthly_amount]
  end
end
