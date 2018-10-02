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
    flash[:error] = 'Sorry, we could not authenticate you. Please try again later.'

    if session[:new_site_url]
      redirect_to root_path
    else
      redirect_to new_user_session_path
    end
  end

  private

  def handle_oauth_callback
    response = SignInUser.new(request).call

    sign_in response.user, event: :authentication

    flash[:event] = response.event if response.event

    redirect_to response.redirect_url || after_sign_in_path_for(response.user)
  end

  def show_invalid_credentials_error(invalid)
    flash[:error] = invalid.record.errors.full_messages.uniq.join('. ') << '.'
    redirect_to root_path
  end

  def show_could_not_authenticate
    flash[:error] = 'Sorry, we could not authenticate you at the moment.'
    redirect_to root_path
  end
end
