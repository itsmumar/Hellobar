class Referrals::HandleToken < Less::Interaction
  expects :user
  expects :token, allow_nil: true

  def run
    return if token.nil?
    return if user.sites.count > 1

    token_record = ReferralToken.where(token: token).first

    if token_record&.belongs_to_a?(User)
      create_from_user_token(token_record)
    elsif token_record&.belongs_to_a?(Referral)
      update_from_referral_token(token_record)
    end
  end

  private

  def create_from_user_token(user_token)
    Referrals::Create.run(
      sender: user_token.tokenizable,
      params: { email: user.email, recipient: user, state: 'signed_up' },
      send_emails: false
    )
  end

  def update_from_referral_token(referral_token)
    referral = referral_token.tokenizable
    referral.recipient = user
    referral.state = :signed_up
    referral.save
    referral
  end
end
