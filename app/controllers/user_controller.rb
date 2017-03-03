class UserController < ApplicationController
  layout 'static', only: [:new, :create]
  before_action :authenticate_user!, except: [:new, :create]
  before_action :load_user, :only => [:edit, :update, :destroy]

  def new
    load_user_from_invitation

    if @user.nil? || @user.invite_token_expired?
      flash[:error] = 'This invitation token has expired.  Please request the owner to issue you a new invitation.'
      redirect_to root_path
    end
  end

  def create
    load_user_from_invitation
    attr_hash = user_params.delete(:email)
    attr_hash = user_params.merge!(status: User::ACTIVE_STATUS)
    if @user.update(attr_hash)
      sign_in @user, event: :authentication
      redirect_to after_sign_in_path_for(@user)
    else
      flash[:error] = @user.errors.full_messages.uniq.join('. ') << '.'
      render 'new'
    end
  end

  def update
    active_before_update = @user.active?

    if can_attempt_update?(@user, user_params) && @user.update_attributes(user_params.merge(:status => User::ACTIVE_STATUS))
      sign_in @user, :bypass => true

      set_timezones_on_sites(@user)

      respond_to do |format|
        format.html do
          flash[:success] = active_before_update ? 'Your settings have been updated.' : 'Your account has been created.'
          redirect_to current_site ? site_path(current_site) : new_site_path
        end

        format.json { render json: {user: @user, redirect_to: (current_site ? site_path(current_site) : new_site_path)}, status: :ok }
      end
    else
      @user.reload # Don't persist any changes

      error_message =
        if active_before_update
          "There was a problem updating your settings#{@user.errors.any? ? ": #{@user.errors.full_messages.first.downcase}." : '.'}"
        else
          "There was a problem creating your account#{@user.errors.any? ? ": #{@user.errors.full_messages.first.downcase}." : '.'}"
        end

      respond_to do |format|
        format.html do
          if active_before_update
            flash.now[:error] = error_message
            render :action => :edit
          else
            flash[:error] = error_message
            redirect_to request.referrer || after_sign_in_path_for(@user)
          end
        end

        format.json { render json: {error_message: error_message}, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @user.destroy
    if @user.destroyed?
      respond_to do |format|
        format.html do
          flash[:success] = 'Account successfully deleted.'
          sign_out @user
          redirect_to root_path
        end
        format.json { render json: {success: true}, status: :ok }
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:error] = "There was a problem deleting your account#{@user.errors.any? ? ": #{@user.errors.full_messages.first.downcase}." : '.'}"
          render :action => :edit
        end
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def load_user_from_invitation
    token = params[:token] || params[:invite_token] || params[:user].try(:[], :invite_token)
    return nil unless token

    @user = User.where(invite_token: token, status: User::TEMPORARY_STATUS).first
  end

  def set_timezones_on_sites(user)
    if params[:user] && params[:user][:timezone]
      timezone = params[:user][:timezone]

      user.sites.each do |site|
        site.update_attribute :timezone, timezone unless site.timezone
      end
    end
  end

  def can_attempt_update?(user, user_params)
    # If the user is active then they must supply a current_password
    # to update the password.
    if user.active?
      if !user.is_oauth_user? && user_params[:password].present?
        unless user.valid_password?(params[:user][:current_password])
          user.errors.add(:current_password, 'is incorrect')
          return false
        end
        # forbid setting new password equal to the old one
        if params[:user][:current_password] == params[:user][:password]
          user.errors.add(:new_password, 'should not match the old one')
          return false
        end
      end
      true
    else
      # If the user is not active then they must supply an email and password
      user_params[:password].present? && user_params[:email].present?
    end
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
