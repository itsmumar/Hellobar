class Admin::UsersController < ApplicationController
  layout "admin"

  before_action :require_admin

  def index
    if params[:q].blank?
      users = User.all
      sites = []
    else
      users = User.where("email like ?", "%#{params[:q]}%").all
      sites = Site.where("url like ?", "%#{params[:q]}%").all
    end

    users += sites.map{|s| s.users}.flatten

    @users = Kaminari.paginate_array(users).page(params[:page]).per(24)
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
