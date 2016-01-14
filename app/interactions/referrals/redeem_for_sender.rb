# Subscribing a free user to pro or re-attempting a failed billing attempt should
# trigger the calculation in Bill#set_final_amount! which will then run
# CouponUses::ApplyFromReferrals
class Referrals::DoesNotBelongToUser < StandardError ; end
class Referrals::RedeemForSender < Less::Interaction
  expects :referral

  def run
    return unless site.present?
    return unless subscription.present?
    return unless user.present?
    raise Referrals::DoesNotBelongToUser.new unless referral.sender == user

    if subscription.is_a?(Subscription::Free)
      site.change_subscription(new_pro_subscription)
    elsif subscription.problem_with_payment?
      problematic_bill.attempt_billing!
    end
  end

  private

  def new_pro_subscription
    subscription = Subscription::Pro.new
    subscription.user = user
    subscription.schedule = 'monthly'
    subscription
  end

  def problematic_bill
    @problematic_bill ||= subscription.active_bills.order('id DESC').detect do |bill|
      bill.problem_with_payment?(subscription.payment_method)
    end
  end

  def site
    @site ||= referral.site
  end

  def subscription
    site.current_subscription
  end

  def user
    subscription.try(:user)
  end
end