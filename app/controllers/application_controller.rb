class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def access_token
    @access_token ||= Digest::SHA256.hexdigest(["hellobar", request.remote_ip, request.user_agent, access_cookie, "a776b"].join)
  end

  def access_cookie
    cookies[:adxs] ||= {
      :value => Digest::SHA256.hexdigest(["a", rand(10_000), Time.now.to_f, request.user_agent, "d753d"].collect{|s| s.to_s}.join),
      :expires => 90.days.from_now,
      :httponly => true
    }
  end
end
