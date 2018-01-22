class AddHellobar101PromoCodeCoupon < ActiveRecord::Migration
  def up
    Coupon.create!(
      label: 'hellobar101',
      amount: Subscription::Pro.defaults[:monthly_amount] * 1,
      public: true
    )
  end

  def down
    Coupon.where(label: 'hellobar101').destroy_all
  end
end
