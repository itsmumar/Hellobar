class Api::UsersController < Api::ApplicationController
  def current
    # CurrentUserSerializer is used for campaigns application.
    render json: current_user, serializer: CurrentUserSerializer
  end
end
