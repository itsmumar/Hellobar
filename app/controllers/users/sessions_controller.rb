class Users::SessionsController < Devise::SessionsController
  layout 'static'

  def find_email
    email = params[:user].try(:[], :email)

    @user = User.find_by(email: email)

    if @user
      if (auth = @user.authentications.first)
        redirect_to "/auth/#{ auth.provider }"
      else
        render :find_email
      end
    else
      cookies.delete(:login_email)
      redirect_to new_user_session_path, alert: "Email doesn't exist."
    end
  end

  def create
    email = params[:user].try(:[], :email)

    if User.joins(:authentications).where(email: email).any?
      # The user used oauth to sign in so redirect them to that
      redirect_to "/auth/#{ Authentication.joins(:user).where(users: { email: email }).first.provider }"
    else
      @user = User.find_by(email: user_params[:email])
      set_flash_message(:notice, :signed_in) if is_flashing_format?

      if @user.valid_password?(user_params[:password])
        sign_in(@user)

        cookies.permanent[:login_email] = email

        redirect_to after_sign_in_path_for(@user)
      else
        flash.now[:alert] = 'Invalid password.'

        render :find_email
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password)
  end
end
