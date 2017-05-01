class Admin::AccessController < ApplicationController
  layout 'admin'

  before_action :require_admin, only: %i[reset_password do_reset_password logout_admin]
  before_action :redirect_admin, only: :process_step1

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
    return redirect_to(admin_access_path) if params[:login_email].blank?
    email = params[:login_email]

    session[:admin_access_email] = email

    Admin.record_login_attempt(email, remote_ip, user_agent, access_cookie)

    if (@admin = Admin.find_by(email: email))
      process_login(@admin)
    else
      # Always render step2 - this way attackers don't know if the login email is valid or not
      render :step2
    end
  end

  def process_step2
    return redirect_to(admin_access_path) if session[:admin_access_email].blank?
    email = session[:admin_access_email]

    @admin = Admin.find_by(email: email)

    return render :step2 unless @admin
    return redirect_to admin_locked_path if @admin.locked?

    if @admin.validate_login(params[:admin_password], params[:otp])
      session[:admin_token] = @admin.session_token
      redirect_to admin_path
    else
      flash.now[:error] = 'Invalid OTP or password or too many attempts'
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

  def process_login(admin)
    return redirect_to admin_locked_path if admin.locked?
    @admin = admin
    render :step2
  end

  def redirect_admin
    redirect_to(admin_path) if current_admin
  end
end
