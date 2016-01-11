class Referrals::RedeemForReceiver < Less::Interaction
  expects :site

  def run
    return if user.blank?
    return if subscription.blank?
    return unless subscription.trial?
    return unless user.was_referred?

    referral.update(redeemed_by_recipient_at: Time.now)
    site.change_subscription(Subscription::Pro.new(schedule: 'monthly'))
  end

  private

  def subscription
    @subscription ||= site.subscriptions.first
  end

  def user
    subscription.try(:user)
  end

  def referral
    @referral ||= user.received_referral
  end
end