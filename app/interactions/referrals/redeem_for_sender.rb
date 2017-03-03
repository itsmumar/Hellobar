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

class Referrals::NoAvailableReferrals < StandardError ; end
class Referrals::RedeemForSender < Less::Interaction
  include Referrals::ProSubscription
  expects :site

  def run
    return unless subscription.present?
    raise Referrals::NoAvailableReferrals.new unless has_available_referrals?

    if subscription.is_a?(Subscription::Free)
      site.change_subscription(new_pro_subscription)
    elsif subscription.problem_with_payment?
      last_failed_bill.attempt_billing!
    end
  end

  private

  def has_available_referrals?
    Referral.redeemable_by_sender_for_site(site).count > 0
  end

  def last_failed_bill
    @last_failed_bill ||= subscription.active_bills.sort_by(&:id).reverse.detect do |bill|
      bill.problem_with_payment?(subscription.payment_method)
    end
  end

  def subscription
    @subscription ||= site.current_subscription
  end
end
