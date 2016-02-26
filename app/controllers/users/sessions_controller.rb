class Users::SessionsController < Devise::SessionsController
  layout 'static'

  TEMP_MIGRATION_USERS = [
    "sarangan2@gmail.com",
    "oli@unbounce.com"
  ]

  def new
    super
  end

  def find_email
    email = params[:user].try(:[], :email)


    if TEMP_MIGRATION_USERS.include?(email)
      @user = User.new(email: email)
    else
      @user = User.search_all_versions_for_email(email)
    end

    if @user
      cookies.permanent[:login_email] = email

      if auth = @user.authentications.first
        redirect_to "/auth/#{auth.provider}"
      end
    else
      cookies.delete(:login_email)
      redirect_to new_user_session_path, alert: "Email doesn't exist."
    end
  end

  def new
    super
  end

  def create
    email = params[:user].try(:[], :email)

    if Hello::WordpressUser.email_exists?(email) && User.where(email: email).first.nil?

      # user has a 1.0 account, but NOT a 3.0 account
      if current_admin || TEMP_MIGRATION_USERS.include?(email)
        password = params[:user].try(:[], :password)

        if wordpress_user = Hello::WordpressUser.authenticate(email, password, !!current_admin)
          session[:wordpress_user_id] = wordpress_user.id
          redirect_to new_user_migration_path
        else
          @user = User.new

          flash.now[:alert] = "Invalid email or password."
          render action: :new
        end
      else
        render "pages/redirect_login"
      end
    elsif User.joins(:authentications).where(email: email).any?
      # The user used oauth to sign in so redirect them to that
      redirect_to "/auth/#{Authentication.joins(:user).where(users: {email: email}).first.provider}"
    else
      return_val = super
      cookies.permanent[:login_email] = email
      # Record log in
      Analytics.track(*current_person_type_and_id, "Logged In", {ip: request.remote_ip})
      return return_val
    end
  end
end
