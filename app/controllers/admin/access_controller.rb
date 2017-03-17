class Admin::AccessController < ApplicationController
  layout 'admin'

  before_action :require_admin, only: [:reset_password, :do_reset_password, :logout_admin]
  before_action :redirect_admin, only: :step1

  def do_reset_password
    if current_admin.password_hashed != current_admin.encrypt_password(params[:existing_password])
      @error = 'Your existing password is incorrect'
    elsif params[:new_password] != params[:new_password_again]
      @error = 'Your new passwords did not match each other'
    elsif !params[:new_password] || params[:new_password].length < Admin::MIN_PASSWORD_LENGTH
      @error = "New password must be at least #{ Admin::MIN_PASSWORD_LENGTH } chars"
    elsif params[:new_password] == params[:existing_password]
      @error = 'New password must be different than existing password.'
    end

    if @error
      flash.now[:error] = @error
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
    return redirect_to(admin_access_path) unless (email = params[:login_email])

    session[:admin_access_email] = email

    unless Admin.any_validated_access_token?(access_token) || verify_recaptcha
      return redirect_to(admin_access_path)
    end

    Admin.record_login_attempt(email, remote_ip, user_agent, access_cookie)

    if (@admin = Admin.find_by(email: email))
      process_login(@admin)
    else
      # Always render step2 - this way attackers don't know if the login
      # email is valid or not
      render(:step2)
    end
  end

  def process_step2
    return redirect_to(admin_access_path) unless (email = session[:admin_access_email])

    @admin = Admin.where(email: email).first

    return render(:step2) unless @admin
    return redirect_to(admin_locked_path) if @admin.locked?
    return render(:validate_access_token) unless @admin.validated_access_token?(access_token)

    if @admin.validate_login(access_token, params[:admin_password], params[:otp])
      # Successful login
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

  def validate_access_token
    return redirect_to(admin_access_path) unless (email = params[:email])

    admin = Admin.where(email: email).first

    return render(:step2) unless admin
    return redirect_to(admin_locked_path) if admin.locked?

    if admin.validate_access_token(access_token, params[:key], params[:timestamp].to_i)
      process_login(admin)
    else
      render :validate_access_token
    end
  end

  private

  def process_login(admin)
    return redirect_to(admin_locked_path) if admin.locked?

    # If they have validated the access token then we
    # can render step 2
    unless admin.validated_access_token?(access_token)
      admin.send_validate_access_token_email!(access_token)
      return render(:validate_access_token)
    end

    return redirect_to(admin_locked_path) if admin.locked?

    @admin = admin
    render(:step2)
  end

  def redirect_admin
    return redirect_to(admin_path) if current_admin
  end
end
