class Admin::UsersController < AdminController
  def index
    q = params[:q].to_s.strip

    if q.blank?
      @users = User.page(params[:page]).per(24).includes(:authentications)
    else
      users = User.search_by_username(q).includes(:authentications)

      if q =~ /\.js$/
        site = Site.find_by_script(q)
        users += site.owners if site
      else
        users += User.search_by_site_url(q).includes(:authentications)
      end

      if q =~ /\d{4}/
        users += User.joins(:credit_cards).where('credit_cards.number like ?', "%-#{ q }%").uniq
      end

      @users = Kaminari.paginate_array(users.uniq).page(params[:page]).per(24)
    end
  end

  def show
    @user = User.with_deleted.find(params[:id])
  end

  def destroy
    @user = User.find(params[:id])
    DestroyUser.new(@user).call
    flash[:success] = "Deleted user #{ @user.id } (#{ @user.email })"
    redirect_to admin_users_path
  rescue ActiveRecord::ActiveRecordError => e
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
