class AdminController < ApplicationController
  layout "admin"

  before_action :require_admin

  def unlock_all
    Admin.unlock_all!
  end
end
