class Admin::UsersController < ApplicationController
  layout "admin"

  before_action :require_admin

  def index
    if params[:q].blank?
      @users = User.page(params[:page]).per(24)
    else
      users = User.with_deleted.where("email like ?", "%#{params[:q].strip}%").all
      users += User.joins(:sites).where("url like ?", "%#{params[:q].strip}%").all

      if params[:q].strip =~ /\d{4}/
        users += PaymentMethodDetails.where("data like ?", "%-#{params[:q].strip}%").map(&:user).compact
      end

      @users = Kaminari.paginate_array(users.uniq).page(params[:page]).per(24)
    end
  end

  def show
    @user = User.with_deleted.find(params[:id])
  end

  def destroy
    @user = User.find(params[:id])
    if @user.destroy
      flash[:success] = "Deleted user #{@user.id} (#{@user.email})"
      redirect_to admin_users_path
    else
      flash[:error] = "Failed to delete user."
      redirect_to admin_user_path(@user)
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
