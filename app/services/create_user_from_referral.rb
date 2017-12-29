class CreateUserFromReferral
  attr_reader :token

  def initialize(token)
    @token = token
  end

  def call
    token_record = ReferralToken.find_by!(token: token)

    case token_record.tokenizable
    when Referral
      handle_referral(token_record.tokenizable)
    when User
      false
    end
  end

  private

  def handle_referral(referall)
    # invite has been already used
    raise ActiveRecord::RecordNotFound unless referall.sent?

    User.find_or_create_temporary_user(referall.email)
  end
end
