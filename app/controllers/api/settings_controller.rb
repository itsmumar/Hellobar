class Api::SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    render json: SettingsSerializer.new(current_user, scope: Site.find(params[:site_id])).as_json
  end
end
