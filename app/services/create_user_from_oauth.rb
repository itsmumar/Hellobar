class CreateUserFromOauth
  def initialize(omniauth_hash, track_options = {})
    @omniauth_hash = omniauth_hash
    @track_options = track_options
  end

  # @return User
  def call
    CreateUser.new(build_user).call
  end

  private

  delegate :info, to: :omniauth_hash

  attr_reader :omniauth_hash, :track_options

  def build_user
    update_attributes find_temporary_user || initialize_user
  end

  def find_temporary_user
    User.find_by(email: info.email, status: User::TEMPORARY)
  end

  def initialize_user
    User.new(email: info.email)
  end

  def update_attributes(user)
    password = Devise.friendly_token[9, 20]

    user.password = password
    user.password_confirmation = password

    user.first_name = info.first_name
    user.last_name = info.last_name

    user.authentications.build(provider: omniauth_hash.provider, uid: omniauth_hash.uid)
    user.status = User::ACTIVE
    user
  end
end
