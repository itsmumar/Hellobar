class AdminController < ApplicationController
  layout "admin"

  before_action :require_admin

  def reports
    @optimizely_experiments = []
  end
end
