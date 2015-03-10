class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.find_for_google_oauth2(request.env["omniauth.auth"], current_user)

    if @user.persisted?
      sign_in @user, event: :authentication
      if session[:new_site_url]
        redirect_to continue_create_site_path
      else
        redirect_to after_sign_in_path_for(@user)
      end
    else
      flash[:notice] = "We couldn't verify with Google.  Please try again."
      redirect_to root_path
    end
  end
end