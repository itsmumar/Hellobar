class CreateReferralCouponRecord < ActiveRecord::Migration
  def up
    # This migration is to fix the development environment due to missing entry
    # in db/seeds.rb
    return unless Rails.env.development?

    coupon = Coupon.create! label: Coupon::REFERRAL_LABEL,
      amount: Coupon::REFERRAL_AMOUNT, public: false

    CouponUse.update_all coupon_id: coupon.id
  end
end
