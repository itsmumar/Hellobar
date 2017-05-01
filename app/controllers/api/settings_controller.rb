class Api::SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    render json: SettingsSerializer.new(current_user).as_json
  end
end
