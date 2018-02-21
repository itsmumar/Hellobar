class Api::ApplicationController < ApplicationController
  abstract!

  prepend_before_action :authenticate_request!
  skip_before_action :verify_authenticity_token

  rescue_from StandardError, with: :render_error
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  respond_to :json

  private

  def authenticate_request!
    return if current_user

    render json: { errors: ['Unauthorized'] }, status: :unauthorized
    false
  end

  def current_user
    @current_user ||= User.find_by(id: auth_payload[:user_id])
  end

  def auth_payload
    @auth_payload ||= JsonWebToken.decode(auth_token)
  rescue JWT::DecodeError
    {}
  end

  def auth_token
    @auth_token ||= request.headers['Authorization'].to_s.split.last
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

  def render_error(exception)
    render json: { errors: [exception.message] },
      status: :internal_server_error
  end
end
