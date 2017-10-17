class UseReferral
  def initialize(bill, referral)
    @bill = bill
    @site = Site.with_deleted.find_by(id: bill.site_id)
    @referral = referral
  end

  def call
    create_coupon_use
    use_up_referral
  end

  private

  attr_reader :bill, :referral, :site

  def create_coupon_use
    CouponUse.create(bill: bill, coupon: referral_coupon)
  end

  def referral_coupon
    @referral_coupon ||= Coupon.for_referrals
  end

  def use_up_referral
    use_up_for_sender || use_up_for_recipient
  end

  def use_up_for_recipient
    return unless for_recipient?
    referral.state = :installed
    referral.available_to_sender = true
    referral.redeemed_by_recipient_at = Time.current
    referral.save!
  end

  def use_up_for_sender
    return unless for_sender?
    referral.available_to_sender = false
    referral.redeemed_by_sender_at = Time.current
    referral.save!
  end

  def for_recipient?
    site.owners.where(id: referral.recipient_id).any?
  end

  def for_sender?
    !for_recipient? && referral.available_to_sender && referral.site_id == bill.site_id
  end
end
