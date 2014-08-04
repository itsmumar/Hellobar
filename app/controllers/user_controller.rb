class UserController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_user, :only => [:edit, :update]

  layout :determine_layout

  def update
    if @user.update_attributes(user_params)
      sign_in @user, :bypass => true
      flash[:success] = "Your settings have been updated."
      redirect_to current_site ? site_path(current_site) : new_site_path
    else
      flash.now[:error] = "There was a problem updating your settings."
      render :action => :edit
    end
  end


  private

  def load_user
    @user = current_user
  end

  def determine_layout
    %w(new edit).include?(action_name) ? "ember" : "application"
  end

  def user_params
    if params[:user] && params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation)
  end
end
