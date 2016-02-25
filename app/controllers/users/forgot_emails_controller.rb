class Users::ForgotEmailsController < ApplicationController
  layout 'static'

  def new
  end

  def create
    @user = User.search_all_versions_for_email(params[:email])

    if @user
      cookies.permanent[:login_email] = @user.email

      if @user.status == User::TEMPORARY_STATUS
        sign_in(@user)

        render :set_password
      elsif authentication = @user.authentications.first
        redirect_to "/auth/#{authentication.provider}"
      else # password
        render :enter_password
      end
    else
      flash.now[:error] = 'No account with the email address could be found.'
      render :new
    end
  end
end
