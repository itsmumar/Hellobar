class CreateTemporaryUser
  attr_reader :email

  def initialize(email)
    @email = email
  end

  def call
    find_user || create_user
  end

  private

  def find_user
    User.find_by(email: email, status: User::TEMPORARY)
  end

  def create_user
    password = Devise.friendly_token[9, 20]

    User.create email: email,
                status: User::TEMPORARY,
                password: password,
                password_confirmation: password
  end
end
