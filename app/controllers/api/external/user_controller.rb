class Api::External::UserController < Api::External::ApplicationController
  before_action -> { doorkeeper_authorize! :email }

  def show
    respond_with(email: current_user.email)
  end
end
