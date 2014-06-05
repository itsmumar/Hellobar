class UserController < ApplicationController
  layout "with_sidebar"

  before_filter :authenticate_user!
  before_filter :load_user, :only => [:edit, :update]

  def update
    if @user.update_attributes(user_params)
      sign_in @user, :bypass => true
      redirect_to current_site ? site_path(current_site) : new_site_path
    else
      render :action => :edit
    end
  end


  private

  def load_user
    @user = current_user
  end

  def user_params
    if params[:user] && params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation)
  end
end
