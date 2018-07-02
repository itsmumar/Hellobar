class Api::Internal::ApplicationController < ApplicationController
  abstract!

  skip_before_action :verify_authenticity_token
  before_action :authenticate

  respond_to :json

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      token == Settings.api_token
    end
  end
end
