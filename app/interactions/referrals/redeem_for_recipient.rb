# Redeem coupons for a referral recipient.
#
# This is a new user. Since they have installed the widget, move them to a
# monthly pro subscription.
#
# The subscription change will trigger the calculation in Bill#set_final_amount!
# which will then run CouponUses::ApplyFromReferrals
#

class Referrals::NotInstalled < StandardError; end
class Referrals::RedeemForRecipient < Less::Interaction
  expects :site

  def run
    return if subscription.blank?
    return if user.blank?
    return unless user.was_referred?

    raise Referrals::NotInstalled unless user.received_referral.state == 'installed'

    sub = Subscription::Pro.new
    sub.user = user
    sub.schedule = 'monthly'
    site.change_subscription(sub)
  end

  private

  def subscription
    @subscription ||= site.subscriptions.first
  end

  def user
    subscription.user
  end

  def referral
    @referral ||= user.received_referral
  end
end