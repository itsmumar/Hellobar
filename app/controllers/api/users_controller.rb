class Api::UsersController < Api::ApplicationController
  def current
    render json: current_user, serializer: CurrentUserSerializer
  end
end
