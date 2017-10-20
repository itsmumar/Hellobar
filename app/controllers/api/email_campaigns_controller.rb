class Api::EmailCampaignsController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :authenticate

  respond_to :json

  def update_status
    email_campaign.update(
      status: email_campaign_params[:status],
      sent_at: Time.current
    )

    head :ok
  end

  private

  def email_campaign_params
    params.require(:email_campaign).permit :status
  end

  def email_campaign
    @email_campaign ||= EmailCampaign.find params[:id]
  end

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      token == Settings.api_token
    end
  end
end
