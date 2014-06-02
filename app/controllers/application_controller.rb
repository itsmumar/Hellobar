class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method :access_token, :current_admin

  def access_token
    @access_token ||= Digest::SHA256.hexdigest(["hellobar", remote_ip, user_agent, access_cookie, "a776b"].join)
  end

  def access_cookie
    cookies[:adxs] ||= {
      :value => Digest::SHA256.hexdigest(["a", rand(10_000), Time.now.to_f, user_agent, "d753d"].collect{|s| s.to_s}.join),
      :expires => 90.days.from_now,
      :httponly => true
    }
  end

  def user_agent
    request.user_agent
  end

  def remote_ip
    request.remote_ip
  end

  def current_admin
    @current_admin ||= Admin.validate_session(access_token, session[:admin_token])
  end

  def require_admin
    if current_admin.nil?
      redirect_to root_path
    elsif current_admin.needs_to_set_new_password?
      redirect_to(admin_reset_password_path) unless URI.parse(url_for).path == admin_reset_password_path
    end
  end

  def after_sign_in_path_for(resource)
    sites_path
  end
end
