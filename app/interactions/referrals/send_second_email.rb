class Referrals::SendSecondEmail < Less::Interaction
  expects :referral

  def run
    return if referral.accepted?
    return if referral.recipient.present?
    return if referral.created_at < Referral::FOLLOWUP_INTERVAL.ago

    ReferralsMailer.second_invite(referral).deliver_later
  end
end
