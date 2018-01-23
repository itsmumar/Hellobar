class AddHellobar101PromoCodeCoupon < ActiveRecord::Migration
  def up
    Coupon.create!(
      label: 'hellobar101',
      trial_period: 30,
      public: true,
      amount: Subscription::Pro.defaults[:monthly_amount]
    )
  end

  def down
    Coupon.where(label: 'hellobar101').destroy_all
  end
end
