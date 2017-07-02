class AdminController < ApplicationController
  layout 'admin'

  before_action :require_admin

  private

  def require_admin
    return redirect_to(admin_access_path, alert: 'Access denied') unless current_admin
    return unless current_admin.needs_to_set_new_password?
    redirect_to(admin_reset_password_path) unless URI.parse(url_for).path == admin_reset_password_path
  end
end
