class Users::SessionsController < Devise::SessionsController
  layout 'static'

  TEMP_MIGRATION_USERS = [
    'sarangan2@gmail.com',
    'oli@unbounce.com'
  ]

  def find_email
    email = params[:user].try(:[], :email)

    @user =
      if TEMP_MIGRATION_USERS.include?(email)
        User.new(email: email)
      else
        User.search_all_versions_for_email(email)
      end

    if @user
      if @user.wordpress_user?
        # render find_email
      elsif @user.status == User::TEMPORARY_STATUS
        sign_in(@user)

        render 'users/forgot_emails/set_password'
      elsif (auth = @user.authentications.first)
        redirect_to "/auth/#{ auth.provider }"
      end
    else
      cookies.delete(:login_email)
      redirect_to new_user_session_path, alert: "Email doesn't exist."
    end
  end

  def create
    email = params[:user].try(:[], :email)

    if Hello::WordpressUser.email_exists?(email) && User.where(email: email).first.nil?

      # user has a 1.0 account, but NOT a 3.0 account
      if current_admin || TEMP_MIGRATION_USERS.include?(email)
        password = params[:user].try(:[], :password)

        if (wordpress_user = Hello::WordpressUser.authenticate(email, password, !current_admin.nil?))
          session[:wordpress_user_id] = wordpress_user.id
          redirect_to new_user_migration_path
        else
          @user = User.new

          flash.now[:alert] = 'Invalid email or password.'
          render action: :find_email
        end
      else
        render 'pages/redirect_login'
      end
    elsif User.joins(:authentications).where(email: email).any?
      # The user used oauth to sign in so redirect them to that
      redirect_to "/auth/#{ Authentication.joins(:user).where(users: { email: email }).first.provider }"
    else
      @user = User.find_by(email: user_params[:email])
      set_flash_message(:notice, :signed_in) if is_flashing_format?

      if @user.valid_password?(user_params[:password])
        sign_in(@user)

        cookies.permanent[:login_email] = email
        # Record log in
        Analytics.track(*current_person_type_and_id, 'Logged In', ip: request.remote_ip)

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
