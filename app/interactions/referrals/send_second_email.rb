class Referrals::SendSecondEmail < Less::Interaction
  expects :referral

  def run
    return if referral.accepted?
    return if referral.recipient.present?
    return if referral.created_at < Referral::FOLLOWUP_INTERVAL.ago

    MailerGateway.send_email("Referal Invite Second", referral.email, {
      referral_sender: referral.sender.name,
      referral_expiration_date: referral.expiration_date_string,
      referral_link: referral.url
    })
  end
end
