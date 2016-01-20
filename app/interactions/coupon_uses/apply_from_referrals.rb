class CouponUses::ApplyFromReferrals < Less::Interaction
  expects :bill

  def run
    return if user.blank?
    return if bill.is_a?(Bill::Refund)
    return unless bill.amount > 0

    Referral.redeemable_by_user(user).take_while do |referral|
      apply_referral_coupon
      use_up(referral)

      bill.amount > 0
    end
  end

  private

  def user
    bill.subscription.user
  end

  def apply_referral_coupon
    bill.amount -= Coupon::REFERRAL_AMOUNT
    bill.discount += Coupon::REFERRAL_AMOUNT
    bill.amount = 0 if bill.amount < 0
    bill.discount = bill.base_amount if bill.discount > bill.base_amount

    CouponUse.create(bill: bill, coupon: Coupon.for_referrals)
  end

  def use_up(referral)
    if referral.recipient_id == user.id
      referral.state = :installed
      referral.available_to_sender = true
      referral.redeemed_by_recipient_at = Time.now
      referral.save!
    elsif referral.sender_id == user.id
      referral.available_to_sender = false
      referral.redeemed_by_sender_at = Time.now
      referral.save!
    end
  end
end