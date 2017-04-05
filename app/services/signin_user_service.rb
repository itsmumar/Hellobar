class SigninUserService
  # @param [ActionDispatch::Request] request
  def initialize(request)
    @request = request
  end

  def signin
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
    user.update_authentication(**authentication_params) if should_update_authentication?(user)

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

  def authentication_params
    omniauth.symbolize_keys.slice(:info, :credentials, :uid, :provider)
  end

  def cookies
    request.cookie_jar
  end

  def omniauth
    request.env['omniauth.auth']
  end

  def track_options
    { ip: request.remote_ip, url: session[:new_site_url] }
  end

  def find_user
    return unless omniauth && omniauth['info'].present?
    User.find_by(email: omniauth['info']['email'])
  end

  def create_user
    user = User.find_for_google_oauth2(omniauth, cookies[:login_email], track_options)
    create_lead(user)
    user
  end

  def create_lead(user)
    return unless user
    user.build_lead(first_name: user.first_name, last_name: user.last_name).save(validate: false)
  end
end
