class Users::OmniauthCallbacksController < ApplicationController
  def google_oauth2
    track_options = {ip: request.remote_ip, url: session[:new_site_url]}

    @user = User.find_by(email: request.env["omniauth.auth"].info[:email])

    if @user.authentications.exists?
      @user = User.find_for_google_oauth2(request.env["omniauth.auth"], cookies[:login_email], track_options)
    end

    if @user.persisted?
      sign_in @user, event: :authentication
      cookies.permanent[:login_email] = @user.email

      if session[:new_site_url]
        redirect_to continue_create_site_path
      else
        redirect_to after_sign_in_path_for(@user)
      end
    else
      if @user.errors.any?
        cookies.delete(:login_email)
        flash[:error] = @user.errors.full_messages.uniq.join(". ") << "."
      else
        flash[:error] = "We could not authenticate with Google."
      end
      redirect_to root_path
    end
  end

  def failure
    if session[:new_site_url]
      flash[:error] = "Sorry, we could not authenticate with Google. Please try again."
      redirect_to root_path
    else
      flash[:error] = "Sorry, we could not authenticate with Google. Please try again."
      redirect_to new_user_session_path
    end
  end
end
