class SignInUser
  # @param [ActionDispatch::Request] request
  def initialize(request)
    @request = request
  end

  def call
    user, redirect_url = find_or_create_user
    user.save!
    cookies.permanent[:login_email] = user.email
    yield user, redirect_url
  end

  private

  attr_reader :request

  include Rails.application.routes.url_helpers
  delegate :session, to: :request

  def find_or_create_user
    user = find_user
    user.update_authentication(omniauth_hash) if should_update_authentication?(user)

    [user || create_user, redirect_url_for(user)]
  end

  def redirect_url_for(user)
    if session[:new_site_url] && user
      new_site_path(url: session[:new_site_url])
    elsif session[:new_site_url]
      continue_create_site_path
    end
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

  def track_options
    { ip: request.remote_ip, url: session[:new_site_url] }
  end

  def find_user
    return if omniauth_hash&.info.blank?

    User.find_by(email: omniauth_hash.info.email)
  end

  def create_user
    User.find_for_google_oauth2(omniauth_hash, cookies[:login_email], track_options)
  end
end
