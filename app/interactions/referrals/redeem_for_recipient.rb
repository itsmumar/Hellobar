# Redeem coupons for a referral recipient.
#
# This is a new user. Since they have installed the widget, move them to a
# monthly pro subscription.
#
# The subscription change will trigger the calculation in Bill#set_final_amount!
# which will then run CouponUses::ApplyFromReferrals
#

class Referrals::NotSignedUp < StandardError; end
class Referrals::RedeemForRecipient < Less::Interaction
  expects :site

  def run
    return if current_subscription.blank?
    return if user.blank?
    return unless user.was_referred?
    return if already_accepted_referral?

    raise Referrals::NotSignedUp unless user.received_referral.signed_up?

    user.received_referral.update_attributes(state: :installed, available_to_sender: true)
    ChangeSubscription.new(site, plan: 'pro', schedule: 'monthly').call
    redeem_for_sender
    send_success_email_to_sender
  rescue Referrals::NotSignedUp => ex
    # This really is an exceptional situation, but because the caller of this interaction,
    # Site#script_installed? is referenced from so many places, let's play it safe
    # and not have the user see an exception they're not directly affected by.
    Raven.capture_exception(ex)
  end

  private

  def already_accepted_referral?
    referral.state == :installed || referral.redeemed_by_recipient_at?
  end

  def current_subscription
    @subscription ||= site.subscriptions.first
  end

  def user
    @user ||= site.owners.first
  end

  def referral
    @referral ||= user.received_referral
  end

  def redeem_for_sender
    # This will be a no-op if the user is already on Free Pro
    Referrals::RedeemForSender.run(site: referral.site) if referral.site
  end

  def send_success_email_to_sender
    MailerGateway.send_email(
      'Referral Successful',
      referral.sender.email,
      referral_sender: referral.sender.first_name,
      referral_recipient: user.name
    )
  end
end
