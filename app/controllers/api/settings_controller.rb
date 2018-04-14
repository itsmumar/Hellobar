class Api::SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    render json: current_user,
           serializer: SettingsSerializer,
           scope: Site.find(params[:site_id])
  end
end
