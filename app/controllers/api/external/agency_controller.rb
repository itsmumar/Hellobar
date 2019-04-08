class Api::External::AgencyController < ActionController::Base
  http_basic_authenticate_with name: Settings.agency_username, password: Settings.agency_password

  def provision_account
    CreateUserFromAgency.new(params).call
    render json: { success: true }
  end
end
