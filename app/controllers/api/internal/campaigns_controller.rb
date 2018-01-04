class Api::Internal::CampaignsController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :authenticate

  respond_to :json

  def update_status
    campaign.update(
      status: campaign_params[:status],
      sent_at: Time.current
    )

    head :ok
  end

  private

  def campaign_params
    params.require(:campaign).permit :status
  end

  def campaign
    @campaign ||= Campaign.find params[:id]
  end

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      token == Settings.api_token
    end
  end
end
