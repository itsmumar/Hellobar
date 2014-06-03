class Admin::UsersController < ApplicationController
  layout "admin"

  before_filter :require_admin

  def index
    if params[:q].blank?
      users = User.all
    else
      users = User.where("email like ?", "%#{params[:q]}%").all
    end

    @users = users.page(params[:page])
  end

  def impersonate
    @user = User.find(params[:id])
    session[:impersonated_user] = @user.id

    redirect_to after_sign_in_path_for(@user)
  end

  def unimpersonate
    session.delete(:impersonated_user)
    redirect_to admin_users_path
  end
end
