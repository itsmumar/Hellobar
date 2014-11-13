class Admin::UsersController < ApplicationController
  layout "admin"

  before_action :require_admin

  def index
    if params[:q].blank?
      @users = User.page(params[:page]).per(24)
    else
      users = User.where("email like ?", "%#{params[:q].strip}%").all
      sites = Site.where("url like ?", "%#{params[:q].strip}%").all
      users += sites.map{|s| s.users}.flatten

      @users = Kaminari.paginate_array(users.uniq).page(params[:page]).per(24)
    end
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
