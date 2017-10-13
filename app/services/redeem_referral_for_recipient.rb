class RedeemReferralForRecipient
  def initialize(site)
    @site = site
    @recipient = site.owners.first
    @referral = recipient.received_referral
  end

  def call
    return unless can_redeem_referral?

    update_referral
    update_subscription
    redeem_for_sender
    send_success_email_to_sender
  end

  private

  attr_reader :site, :recipient, :referral

  def can_redeem_referral?
    recipient.present? &&
      recipient.was_referred? &&
      referral.signed_up? &&
      !referral.already_accepted?
  end

  def update_referral
    referral.update_attributes(state: :installed, available_to_sender: true)
  end

  def update_subscription
    bill = AddTrialSubscription.new(site, subscription: 'pro', trial_period: 1.month).call
    use_referral bill, referral
  end

  def use_referral(bill, referral)
    UseReferral.new(bill, referral).call
  end

  def redeem_for_sender
    Referrals::RedeemForSender.run(referral: referral)
  end

  def send_success_email_to_sender
    ReferralsMailer.successful(referral, recipient).deliver_later
  end
end
