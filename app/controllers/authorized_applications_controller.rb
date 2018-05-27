class AuthorizedApplicationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @access_tokens = Doorkeeper::AccessToken.active_for(current_user).includes(:application)
  end

  def destroy
    @access_token = Doorkeeper::AccessToken.find(params[:id])
    @access_token.update(revoked_at: Time.current)
    redirect_to authorized_applications_path, notice: I18n.t(:notice, scope: [:doorkeeper, :flash, :authorized_applications, :destroy])
  end
end
