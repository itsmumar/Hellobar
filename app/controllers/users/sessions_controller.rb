class Users::SessionsController < Devise::SessionsController
  layout 'static'

  def create
    email = params[:user].try(:[], :email)

    if Hello::WordpressUser.email_exists?(email) && User.where(email: email).first.nil?
      # user has a 1.0 account, but NOT a 3.0 account
      password = params[:user].try(:[], :password)

      if wordpress_user = Hello::WordpressUser.authenticate(email, password)
        session[:wordpress_user_id] = wordpress_user.id
        redirect_to new_user_migration_path
      else
        @user = User.new

        flash.now[:alert] = "Invalid email or password."
        render action: :new
      end
    else
      return_val = super
      # Record log in
      Analytics.track(*current_person_type_and_id, "Logged In", {ip: request.remote_ip})
      return return_val
    end
  end
  
end
