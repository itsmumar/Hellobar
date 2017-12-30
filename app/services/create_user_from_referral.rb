class CreateUserFromReferral
  attr_reader :token

  def initialize(token)
    @token = token
  end

  def call
    token_record = find_token

    case token_record.tokenizable
    when Referral
      handle_referral(token_record.tokenizable)
    when User
      false
    end
  end

  private

  def find_token
    ReferralToken.find_by!(token: token)
  end

  def handle_referral(referall)
    # invite has been already used
    raise ActiveRecord::RecordNotFound unless referall.sent?

    CreateTemporaryUser.new(referall.email).call
  end
end
