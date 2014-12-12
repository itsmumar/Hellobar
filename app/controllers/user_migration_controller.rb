class UserMigrationController < ApplicationController
  before_filter :verify_wordpress_user

  def new
    @bars = @user.bars
  end

  private

  def verify_wordpress_user
    unless session[:wordpress_user_id] && @user = Hello::WordpressUser.where(id: session[:wordpress_user_id]).first
      return redirect_to(new_user_session_path)
    end
  end
end
