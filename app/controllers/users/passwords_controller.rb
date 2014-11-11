class Users::PasswordsController < Devise::PasswordsController
  layout 'static'

  def create
    if Hello::WordpressUser.email_exists?(params[:user].try(:[], :email))
      render "pages/redirect_forgot"
    else
      super
    end
  end
end
