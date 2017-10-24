class CreateUser
  def initialize(omniauth_hash, original_email = nil, track_options = {})
    @omniauth_hash = omniauth_hash
    @original_email = original_email
    @track_options = track_options
  end

  def call
    create_user.tap do |user|
      TrackEvent.new(:signed_up, user: user).call
      Analytics.track(:user, user.id, 'Signed Up', track_options)
      Analytics.track(:user, user.id, 'Completed Signup', email: user.email)
    end
  end

  private

  delegate :info, to: :omniauth_hash

  attr_reader :omniauth_hash, :original_email, :track_options

  def create_user
    # the user is trying to login with a different Google account
    raise_invalid_error if different_google_email?

    update_attributes_and_save find_temporary_user || initialize_user
  end

  def find_temporary_user
    User.find_by(email: info.email, status: User::TEMPORARY)
  end

  def initialize_user
    User.new(email: info.email)
  end

  def update_attributes_and_save(user)
    password = Devise.friendly_token[9, 20]

    user.password = password
    user.password_confirmation = password

    user.first_name = info.first_name
    user.last_name = info.last_name

    user.authentications.build(provider: omniauth_hash.provider, uid: omniauth_hash.uid)
    user.status = User::ACTIVE
    user.save!
    user
  end

  def different_google_email?
    original_email.present? && info.email != original_email
  end

  def raise_invalid_error
    user = User.new
    user.errors.add(:base, "Please log in with your #{ original_email } Google email")
    raise ActiveRecord::RecordInvalid, user
  end
end
