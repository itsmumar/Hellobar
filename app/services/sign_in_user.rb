class SignInUser
  # @param [ActionDispatch::Request] request
  def initialize(request)
    @request = request
  end

  def call
    user, redirect_url = find_or_create_user
    user.save!
    cookies.permanent[:login_email] = user.email

    [user, redirect_url]
  end

  private

  attr_reader :request

  include Rails.application.routes.url_helpers
  delegate :session, to: :request

  def find_or_create_user
    if (user = find_user)
      update_authentication(user, omniauth_hash) if should_update_authentication?(user)
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

  def should_update_authentication?(user)
    user.present? && user.oauth_user?
  end

  def cookies
    request.cookie_jar
  end

  def omniauth_hash
    request.env['omniauth.auth']
  end

  def find_user
    by_email || by_uid
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

  def update_authentication(user, omniauth_hash)
    authentication = user.authentications.find_by(uid: omniauth_hash.uid, provider: omniauth_hash.provider)

    user.first_name = omniauth_hash.info.first_name if omniauth_hash.info.first_name.present?
    user.last_name = omniauth_hash.info.last_name if omniauth_hash.info.last_name.present?

    if omniauth_hash.credentials && user.persisted?
      authentication.update(
        refresh_token: omniauth_hash.credentials.refresh_token,
        access_token: omniauth_hash.credentials.token,
        expires_at: Time.zone.at(omniauth_hash.credentials.expires_at)
      )
    end

    user.save!
  end

  def create_user
    track_options = { ip: request.remote_ip, url: session[:new_site_url] }
    user = CreateUser.new(omniauth_hash, cookies[:login_email], track_options).call
    [user, redirect_url_for_new_user]
  end
end
