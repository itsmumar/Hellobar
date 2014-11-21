class AdminController < ApplicationController
  layout "admin"

  before_action :require_admin

  def reports
    @optimizely_experiments = InternalReport.where("name like 'Optimizely: %'").select("DISTINCT(NAME)").map{|p| p["NAME"]}
  end
end
