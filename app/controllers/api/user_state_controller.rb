class Api::UserStateController < ApplicationController
  before_action :verify_access

  def show
    user = User.find(params[:id])

    render json: ApiSerializer::UserStateSerializer.new(user).to_json
  end

  private

  def verify_access
    return false if params[:api_token].blank?

    Admin.find_by(api_token: params[:api_token]).present? ? nil : head(404)
  end
end
