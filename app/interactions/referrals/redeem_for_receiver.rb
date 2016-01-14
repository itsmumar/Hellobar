class Referrals::NotInstalled < StandardError; end
class Referrals::RedeemForReceiver < Less::Interaction
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
    subscription.try(:user)
  end

  def referral
    @referral ||= user.received_referral
  end
end