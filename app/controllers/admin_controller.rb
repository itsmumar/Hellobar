class AdminController < ApplicationController
  layout 'admin'

  before_action :require_admin

  private

  def require_admin
    redirect_to(admin_access_path, alert: 'Access denied') unless current_admin
  end
end
