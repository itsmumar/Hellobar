class Users::OmniauthCallbacksController < ApplicationController
  rescue_from ActiveRecord::ActiveRecordError, with: :show_could_not_authenticate
  rescue_from ActiveRecord::RecordInvalid, with: :show_invalid_credentials_error

  def google_oauth2
    user, redirect_url = SignInUser.new(request).call

    sign_in user, event: :authentication

    redirect_to redirect_url || after_sign_in_path_for(user)
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

  def show_invalid_credentials_error(invalid)
    flash[:error] = invalid.record.errors.full_messages.uniq.join('. ') << '.'
    redirect_to root_path
  end

  def show_could_not_authenticate
    flash[:error] = 'We could not authenticate with Google.'
    redirect_to root_path
  end
end
