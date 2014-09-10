class UserController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user, :only => [:edit, :update]

  def update
    if @user.update_attributes(user_params)
      sign_in @user, :bypass => true

      respond_to do |format|
        format.html do
          flash[:success] = "Your settings have been updated."
          redirect_to current_site ? site_path(current_site) : new_site_path
        end

        format.json { render json: @user, status: :ok }
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:error] = "There was a problem updating your settings."
          render :action => :edit
        end

        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def load_user
    @user = current_user
  end

  # delete password params if blank and the user is active
  def filter_password_params_if_optional
    if @user.active? && params[:user] && params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
  end

  def user_params
    filter_password_params_if_optional

    params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation, :status)
  end
end
