class Users::SessionsController < Devise::SessionsController
  layout 'static'

  def create
    email = params[:user].try(:[], :email)

    if Hello::WordpressUser.email_exists?(email) && User.where(email: email).first.nil?
      # user has a 1.0 account, but NOT a 3.0 account
      render "pages/redirect_login"
    else
      return_val = super
      # Record log in
      Analytics.track(*current_person_type_and_id, "Logged In", {ip: request.remote_ip})
      return return_val
    end
  end
  
end
