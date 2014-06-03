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
end
