class Admin::UsersController < AdminController
  def index
    @users = SearchUsers.new(params).call
  end

  def show
    @user = User.with_deleted.find(params[:id])
  end

  def destroy
    @user = User.find(params[:id])
    DestroyUser.new(@user).call
    flash[:success] = "Deleted user #{ @user.id } (#{ @user.email })"
    redirect_to admin_users_path
  rescue ActiveRecord::RecordNotDestroyed => e
    flash[:error] = 'Could not delete user.'
    redirect_to admin_user_path(e.record)
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
