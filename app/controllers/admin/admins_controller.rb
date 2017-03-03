class Admin::AdminsController < ApplicationController
  before_filter :load_admin, only: [:unlock]
  layout "admin"

  before_action :require_admin

  def index
    @admins = Admin.all
  end

  def unlock
    @admin.unlock!
    redirect_to action: :index, notice: "#{@admin.email} unlocked."
  end

  private

  def load_admin
    @admin = Admin.find(params[:id])
  end
end
