# Creates a User record from the given referral token when it's possible.
class CreateUserFromReferral
  attr_reader :token

  def initialize(token)
    @token = token
  end

  # Tries to create a temporary user for given referral token.
  #
  # @return [User, nil] a temporary user if personal referral link has been used or nil when generic sender token given.
  # @raise [ActiveRecord::RecordNotFound] if token can't be found.
  def call
    token_record = find_token

    case token_record.tokenizable
    when Referral # personalized token has been used so we can create a temporary user
      handle_referral(token_record.tokenizable)
    when User     # generic link has been used so user has to sign up in order to get the discount
      nil
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
