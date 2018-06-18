class SignInUser
  # @param [ActionDispatch::Request] request
  def initialize(request)
    @request = request
  end

  def call
    find_or_create_user
  end

  private

  attr_reader :request

  include Rails.application.routes.url_helpers
  delegate :session, to: :request

  def find_or_create_user
    if user
      update_user
      create_authentication if should_create_authentication?
      update_authentication if should_update_authentication?
      [user, redirect_url_for_existing_user]
    else
      create_user
    end
  end

  def redirect_url_for_existing_user
    new_site_path(url: session[:new_site_url]) if session[:new_site_url]
  end

  def redirect_url_for_new_user
    continue_create_site_path if session[:new_site_url]
  end

  def should_update_authentication?
    authentication.present? && user.present?
  end

  def should_create_authentication?
    authentication.nil? && user.present? &&
      omniauth_hash.credentials.present? &&
      omniauth_hash.provider == 'google_oauth2'
  end

  def cookies
    request.cookie_jar
  end

  def omniauth_hash
    @omniauth_hash ||= request.env['omniauth.auth']
  end

  def user
    @user ||= by_email || by_uid
  end

  def by_email
    return if omniauth_hash&.info.blank?

    User.find_by(email: omniauth_hash.info.email)
  end

  def by_uid
    User
      .joins(:authentications)
      .find_by(authentications: { uid: omniauth_hash.uid, provider: omniauth_hash.provider })
  end

  def update_authentication
    return unless omniauth_hash.credentials && user.persisted?

    authentication.update(
      refresh_token: omniauth_hash.credentials.refresh_token,
      access_token: omniauth_hash.credentials.token,
      expires_at: Time.zone.at(omniauth_hash.credentials.expires_at)
    )
  end

  def create_authentication
    return unless omniauth_hash.credentials && user.persisted?

    user.authentications.create!(
      provider: omniauth_hash.provider,
      refresh_token: omniauth_hash.credentials.refresh_token,
      access_token: omniauth_hash.credentials.token,
      expires_at: Time.zone.at(omniauth_hash.credentials.expires_at)
    )
  end

  def update_user
    user.first_name = omniauth_hash.info.first_name if omniauth_hash.info.first_name.present?
    user.last_name = omniauth_hash.info.last_name if omniauth_hash.info.last_name.present?
    user.save!
  end

  def authentication
    @authentication ||=
      user.authentications.find_by(uid: omniauth_hash.uid, provider: omniauth_hash.provider)
  end

  def create_user
    user = CreateUserFromOauth.new(omniauth_hash).call
    CreateAffiliateInformation.new(user, cookies).call

    [user, redirect_url_for_new_user]
  end
end
