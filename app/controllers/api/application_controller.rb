class Api::ApplicationController < ApplicationController
  abstract!

  before_action :authenticate_request!
  skip_before_action :verify_authenticity_token

  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  respond_to :json

  private

  def authenticate_request!
    @current_site = Site.find payload_site_id
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
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

  def record_invalid exception
    render json: { errors: exception.record.errors.messages },
      status: :unprocessable_entity
  end

  def record_not_found exception
    render json: { errors: [exception.message] },
      status: :not_found
  end

  def handle_error(exception)
    render json: { errors: [exception.message] },
      status: :unprocessable_entity
  end
end
