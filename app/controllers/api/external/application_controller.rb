class Api::External::ApplicationController < ApplicationController
  abstract!

  skip_before_action :verify_authenticity_token
  before_action :doorkeeper_authorize!

  respond_to :json

  private

  def current_user
    @current_user ||= User.find(doorkeeper_token[:resource_owner_id])
  end
end
