class Referrals::Create < Less::Interaction
  expects :sender
  expects :params
  expects :send_emails

  def run
    @referral = sender.sent_referrals.build(params)
    @referral.set_site_if_only_one

    send_initial_email if @referral.save && send_emails

    track_event(@referral)
    @referral
  end

  private

  def send_initial_email
    ReferralsMailer.invite(@referral).deliver_later
  end

  def track_event(referral)
    TrackEvent.new(
      :referred_friend,
      user: sender,
      referral: referral
    ).call
  end
end
