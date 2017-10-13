# Redeem coupons for a referral sender
#
# A Free user will be upgraded to Pro free of charge.
# Someone who has billing problems will have their last failed bill retried.
#
# Subscription changes or billing will trigger the calculation in
# Bill#set_final_amount! which will then run CouponUses::ApplyFromReferrals
#
# This is a no-op for non-free users with no billing issues. Their next
# billing cycle will get the discounts by the mechanism described above.

class Referrals::NoAvailableReferrals < StandardError; end
class Referrals::RedeemForSender < Less::Interaction
  expects :referral

  def run
    raise Referrals::NoAvailableReferrals unless referral.available_to_sender

    if !subscription || subscription.is_a?(Subscription::Free)
      update_subscription
    elsif last_failed_bill
      PayBill.new(last_failed_bill).call
    end
  end

  private

  def update_subscription
    bill = AddTrialSubscription.new(site, subscription: 'pro', trial_period: 1.month).call
    use_referral bill, referral
  end

  def use_referral(bill, referral)
    UseReferral.new(bill, referral).call
  end

  def last_failed_bill
    return if subscription.blank?
    @last_failed_bill ||= subscription.bills.failed.last
  end

  def subscription
    @subscription ||= site.current_subscription
  end

  def site
    @site ||= referral.site
  end
end
