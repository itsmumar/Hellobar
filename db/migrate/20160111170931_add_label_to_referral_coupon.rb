class AddLabelToReferralCoupon < ActiveRecord::Migration
  def change
    Coupon.first.update(label: Coupon::REFERRAL_LABEL)
  end
end
