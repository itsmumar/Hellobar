class RemovePromotionalCodeCoupon < ActiveRecord::Migration
  def up
    Coupon.where(label: 'NEILPATELHB2017').destroy_all
  end

  def down
    Coupon.create! label: 'NEILPATELHB2017', amount: Subscription::Pro.defaults[:monthly_amount] * 2, public: true
  end
end
