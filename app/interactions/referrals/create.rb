class Referrals::Create < Less::Interaction
  class Error < StandardError
  end

  MAX_REFERRALS_PER_DAY = 10

  expects :sender
  expects :params
  expects :send_emails

  def run
    validate_referrals_per_day!

    @referral = sender.sent_referrals.build(params)
    @referral.set_site_if_only_one

    send_initial_email if @referral.save && send_emails

    track_event(@referral)
    @referral
  end

  private

  def validate_referrals_per_day!
    return if sender.sent_referrals.in_last_24_hours.count < MAX_REFERRALS_PER_DAY
    raise Error, "Only #{ MAX_REFERRALS_PER_DAY } invitations are allowed per day"
  end

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
