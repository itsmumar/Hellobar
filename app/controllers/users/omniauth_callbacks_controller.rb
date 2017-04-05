class Users::OmniauthCallbacksController < ApplicationController
  def google_oauth2
    @user, redirect_url = find_or_create_user

    if @user.persisted?
      sign_in @user, event: :authentication
      cookies.permanent[:login_email] = @user.email

      if session[:new_site_url]
        redirect_to redirect_url
      else # logging in
        redirect_to after_sign_in_path_for(@user)
      end
    else
      if @user.errors.any?
        cookies.delete(:login_email)
        flash[:error] = @user.errors.full_messages.uniq.join('. ') << '.'
      else
        flash[:error] = 'We could not authenticate with Google.'
      end
      redirect_to root_path
    end
  end

  def failure
    flash[:error] = 'Sorry, we could not authenticate with Google. Please try again.'

    if session[:new_site_url]
      redirect_to root_path
    else
      redirect_to new_user_session_path
    end
  end

  private

  def find_or_create_user
    user = find_user
    user.update_authentication(**omniauth.symbolize_keys) if user.present? && user.oauth_user?

    redirect_url =
      if user
        new_site_path(url: session[:new_site_url])
      else
        continue_create_site_path
      end

    [user || create_user, redirect_url]
  end

  def omniauth
    request.env['omniauth.auth']
  end

  def track_options
    { ip: request.remote_ip, url: session[:new_site_url] }
  end

  def find_user
    User.find_by(email: omniauth['info']['email'])
  end

  def create_user
    User.find_for_google_oauth2(omniauth, cookies[:login_email], track_options)
  end
end
