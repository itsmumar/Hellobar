class Api::InternalController < Api::ApplicationController
  skip_before_action :authenticate_request!
  skip_before_action :verify_authenticity_token

  before_action :authenticate

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      token == Settings.api_token
    end
  end
end
