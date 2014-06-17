class Users::SessionsController < Devise::SessionsController
  def create
    if Hello::WordpressUser.email_exists?(params[:user].try(:[], :email))
      render "pages/redirect_login"
    else
      super
    end
  end
end
