class AddFirstCoupon < ActiveRecord::Migration
  def change
    Coupon.create(amount: Subscription::Pro.defaults[:monthly_amount])
  end
end
