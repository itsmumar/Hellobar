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
  expects :site

  def run
    return if subscription.blank?
    raise Referrals::NoAvailableReferrals unless available_referrals?

    if subscription.is_a?(Subscription::Free)
      ChangeSubscription.new(site, subscription: 'pro', schedule: 'monthly').call
    elsif last_failed_bill
      PayBill.new(last_failed_bill).call
    end
  end

  private

  def available_referrals?
    Referral.redeemable_by_sender_for_site(site).count > 0
  end

  def last_failed_bill
    @last_failed_bill ||= subscription.bills.failed.last
  end

  def subscription
    @subscription ||= site.current_subscription
  end
end
