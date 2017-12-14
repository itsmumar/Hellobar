class Admin::AccessController < AdminController
  skip_before_action :require_admin, only: %i[step1 process_step1 step2 process_step2 lockdown]
  before_action :ensure_not_logged_in!, only: %i[step1 process_step1 step2 process_step2]
  before_action :ensure_otp_enabled!, only: %i[step2 process_step2]

  def do_reset_password
    error =
      if current_admin.password_hashed != current_admin.encrypt_password(params[:existing_password])
        'Your existing password is incorrect'
      elsif params[:new_password] != params[:new_password_again]
        'Your new passwords did not match each other'
      elsif !params[:new_password] || params[:new_password].length < Admin::MIN_PASSWORD_LENGTH
        "New password must be at least #{ Admin::MIN_PASSWORD_LENGTH } chars"
      elsif params[:new_password] == params[:existing_password]
        'New password must be different than existing password.'
      end

    if error
      flash.now[:error] = error
      render :reset_password
    else
      current_admin.reset_password!(params[:new_password])
      redirect_to admin_path
    end
  end

  def logout_admin
    current_admin.logout!
    session.delete(:admin_token)
    flash[:success] = 'You are now logged out.'

    redirect_to admin_access_path
  end

  def process_step1
    return redirect_to(admin_access_path) if admin_params[:email].blank?

    Admin.record_login_attempt(admin_params[:email], remote_ip, user_agent, access_cookie)
    admin = Admin.find_by(email: admin_params[:email])

    if admin.blank?
      render_invalid_credentials

      return
    end

    if admin.validate_password!(admin_params[:password])
      if Admin.otp_enabled?
        session[:login_admin] = admin.id
        redirect_to admin_otp_path
      else
        login_admin!(admin)
      end

      return
    end

    if admin.locked?
      redirect_to admin_locked_path

      return
    end

    render_invalid_credentials
  end

  def step2
    @admin = Admin.find(session[:login_admin])
  end

  def process_step2
    @admin = session[:login_admin] && Admin.find(session[:login_admin])

    if @admin.blank?
      redirect_to admin_access_path
      return
    end

    if @admin.locked?
      redirect_to admin_locked_path

      return
    end

    if @admin.validate_otp!(admin_params[:otp])
      login_admin!(@admin)
    else
      flash.now[:error] = 'Invalid OTP'
      render :step2
    end
  end

  def lockdown
    if Admin.validate_lockdown(params[:email], params[:key], params[:timestamp].to_i)
      Admin.lockdown!
      render text: 'Admins have been successfully locked down'
    else
      render text: 'Admins could not be locked down'
    end
  end

  private

  def admin_params
    params.require(:admin_session).permit(:email, :password, :otp)
  end

  def ensure_not_logged_in!
    return true unless current_admin
    redirect_to admin_path
  end

  def ensure_otp_enabled!
    return true if Admin.otp_enabled?
    redirect_to admin_access_path
  end

  def render_invalid_credentials
    flash.now[:error] = 'Invalid email or password'
    render :step1
  end

  def login_admin!(admin)
    admin.login!
    session[:admin_token] = admin.session_token
    redirect_to admin_path
  end
end
