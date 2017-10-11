class CouponUses::ApplyFromReferrals < Less::Interaction
  expects :bill

  def run
    return if bill.is_a?(Bill::Refund)
    return if bill.amount.zero?

    Referral.redeemable_for_site(site).take_while do |referral|
      apply_discount
      create_coupon_use
      use_up(referral)

      bill.amount > 0
    end
  end

  private

  def site
    bill.site
  end

  def recipient
    site.owners.first
  end

  def apply_discount
    bill.amount -= referral_coupon.amount
    bill.discount += referral_coupon.amount
    bill.amount = 0 if bill.amount < 0
    bill.discount = bill.base_amount if bill.discount > bill.base_amount
  end

  def create_coupon_use
    CouponUse.create(bill: bill, coupon: referral_coupon)
  end

  def referral_coupon
    @referral_coupon ||= Coupon.for_referrals
  end

  def use_up(referral)
    if recipient && referral.recipient_id == recipient.id
      referral.state = :installed
      referral.available_to_sender = true
      referral.redeemed_by_recipient_at = Time.current
      referral.save!
    elsif referral.available_to_sender && referral.site_id == bill.site_id
      referral.available_to_sender = false
      referral.redeemed_by_sender_at = Time.current
      referral.save!
    end
  end
end
