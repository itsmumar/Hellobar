class UserController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user, :only => [:edit, :update]

  def update
    active_before_update = @user.active?

    if can_attempt_update?(@user, user_params) && @user.update_attributes(user_params.merge(:status => User::ACTIVE_STATUS))
      sign_in @user, :bypass => true

      set_timezones_on_sites(@user)

      respond_to do |format|
        format.html do
          flash[:success] = active_before_update ? "Your settings have been updated." : "Your account has been created."
          redirect_to current_site ? site_path(current_site) : new_site_path
        end

        format.json { render json: @user, status: :ok }
      end
    else
      respond_to do |format|
        format.html do
          if active_before_update
            flash.now[:error] = "There was a problem updating your settings#{@user.errors.any? ? ": #{@user.errors.full_messages.first.downcase}." : "."}"
            render :action => :edit
          else
            flash[:error] = "There was a problem creating your account#{@user.errors.any? ? ": #{@user.errors.full_messages.first.downcase}." : "."}"
            redirect_to request.referrer || after_sign_in_path_for(@user)
          end
        end

        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_timezones_on_sites(user)
    if params[:user] && params[:user][:timezone]
      timezone = params[:user][:timezone]

      user.sites.each do |site|
        site.update_attribute :timezone, timezone unless site.timezone
      end
    end
  end

  def can_attempt_update?(user, params)
    # this guard prevents users from activating unless they supply both a password and email
    # active users, however, can always update
    user.active? ||
      (params[:password].present? && params[:email].present?)
  end

  def load_user
    @user = current_user
  end

  # delete password params if blank and the user is active
  def filter_password_params_if_optional
    if @user.active? && params[:user] && params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
      return true
    else
      return false
    end
  end

  def user_params
    filtered = filter_password_params_if_optional

    params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation)
  rescue ActionController::ParameterMissing => e
    filtered ? {} : raise(e)
  end
end
