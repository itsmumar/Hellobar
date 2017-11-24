class Api::CampaignsController < ApplicationController
  before_action :authenticate_request!

  skip_before_action :verify_authenticity_token

  respond_to :json

  def index
    render json: @current_site.email_campaigns
  end

  private

  def authenticate_request!
    @current_site = Site.find payload_site_id
  rescue JWT::VerificationError, JWT::DecodeError, ActiveRecord::RecordNotFound
    render json: { errors: ['Unauthorized'] },
      status: :unauthorized
  end

  def payload_site_id
    payload[:site_id]
  end

  def payload
    JsonWebToken.decode auth_token
  end

  def auth_token
    request.headers['Authorization'].to_s.split.last
  end
end
