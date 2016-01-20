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
  include Referrals::ProSubscription
  expects :site

  def run
    return if current_subscription.blank?
    return if user.blank?
    return unless user.was_referred?
    return if already_accepted_referral?

    raise Referrals::NotInstalled unless user.received_referral.installed?

    site.change_subscription(new_pro_subscription)
    send_success_email_to_sender
  end

  private

  def already_accepted_referral?
    user.received_referral.redeemed_by_recipient_at.present?
  end

  def current_subscription
    @subscription ||= site.subscriptions.first
  end

  def user
    current_subscription.user
  end

  def referral
    @referral ||= user.received_referral
  end

  def send_success_email_to_sender
    MailerGateway.send_email('Referral Success', referral.sender.email, {
      referral_sender: referral.sender.first_name,
      referral_recipient: user.name,
    })
  end
end