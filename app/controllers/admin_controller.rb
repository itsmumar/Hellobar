class AdminController < ApplicationController
  layout "admin"

  before_action :require_admin

  def index
    @optimizely_experiments = InternalReport.where("name like 'Optimizely: %'").select("DISTINCT(NAME)").map{|p| p["NAME"]}
  end
end
