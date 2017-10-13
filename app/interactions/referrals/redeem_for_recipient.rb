# Redeem coupons for a referral recipient.
#
# This is a new user. Since they have installed the widget, move them to a
# monthly pro subscription.
#
# The subscription change will trigger the calculation in Bill#set_final_amount!
# which will then run CouponUses::ApplyFromReferrals
#

class Referrals::RedeemForRecipient < Less::Interaction
  expects :site

  def run
    return if user.blank?
    return unless user.was_referred?
    return if referral.already_accepted?
    return unless referral.signed_up?

    update_referral
    update_subscription
    redeem_for_sender
    send_success_email_to_sender
  end

  private

  def update_subscription
    bill = AddTrialSubscription.new(site, subscription: 'pro', trial_period: 1.month).call
    use_referral bill, referral
  end

  def use_referral(bill, referral)
    UseReferral.new(bill, referral).call
  end

  def update_referral
    referral.update_attributes(state: :installed, available_to_sender: true)
  end

  def user
    @user ||= site.owners.first
  end

  def referral
    @referral ||= user.received_referral
  end

  def redeem_for_sender
    # This will be a no-op if the user is already on Free Pro
    Referrals::RedeemForSender.run(referral: referral)
  end

  def send_success_email_to_sender
    ReferralsMailer.successful(referral, user).deliver_later
  end
end
