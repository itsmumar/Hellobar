class Users::OmniauthCallbacksController < ApplicationController
  rescue_from ActiveRecord::ActiveRecordError, with: :show_could_not_authenticate
  rescue_from ActiveRecord::RecordInvalid, with: :show_invalid_credentials_error

  def google_oauth2
    handle_oauth_callback
  end

  def subscribers
    handle_oauth_callback
  end

  def failure
    flash[:error] = 'Sorry, we could not authorize you. Please try again later.'

    if session[:new_site_url]
      redirect_to root_path
    else
      redirect_to new_user_session_path
    end
  end

  private

  def handle_oauth_callback
    authorization = SignInUser.new(request).call

    sign_in authorization.user, event: :authentication

    flash[:event] = authorization.event if authorization.new_user?

    redirect_to authorization.redirect_url || after_sign_in_path_for(authorization.user)
  end

  def show_invalid_credentials_error(invalid)
    flash[:error] = invalid.record.errors.full_messages.uniq.join('. ') << '.'
    redirect_to root_path
  end

  def show_could_not_authenticate
    flash[:error] = 'Sorry, we could not authorize you at the moment.'
    redirect_to root_path
  end
end
