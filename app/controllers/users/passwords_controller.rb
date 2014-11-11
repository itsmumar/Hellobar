class Users::PasswordsController < Devise::PasswordsController
  layout 'static'

  def create
    if Hello::WordpressUser.email_exists?(params[:user].try(:[], :email))
      render "pages/redirect_forgot"
    else
      flash[:success] = 'You will receive an email with instructions about how to confirm your account in a few minutes.'
      super
    end
  end
end
