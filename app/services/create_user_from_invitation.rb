class CreateUserFromInvitation
  def initialize(invitation_token, params)
    @invitation_token = invitation_token
    @params = params
  end

  # @return User
  def call
    return unless user

    user.assign_attributes(params.merge(status: User::ACTIVE))
    CreateUser.new(user).call
  end

  private

  attr_reader :invitation_token, :params

  def user
    @user ||= User.find_by(invite_token: invitation_token, status: User::TEMPORARY)
  end
end
