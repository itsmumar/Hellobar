class CouponUses::CreateForReferral < Less::Interaction
  expects :bill

  def run
    return if user.blank?
    return if bill.is_a?(Bill::Refund)
    return unless bill.amount > 0

    referral_iterator = Referral.redeemable_by_user(user).take_while { bill.amount > 0 }
    referral_iterator.each do |r|
      bill.amount -= Coupon::REFERRAL_AMOUNT
      bill.discount += Coupon::REFERRAL_AMOUNT
      bill.amount = 0 if bill.amount < 0
      use_up(r)
    end
  end

  private

  def user
    bill.subscription.try(:user)
  end

  def use_up(referral)
    CouponUse.create(bill: bill, coupon: Coupon.for_referrals)

    if referral.recipient_id == user.id
      referral.redeemed_by_recipient_at = Time.now
      referral.save!
    elsif r.sender_id == user.id
      referral.redeemed_by_sender_at = Time.now
      referral.available = false
      referral.save!
    end
  end
end