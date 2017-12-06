class Api::CampaignsController < ApplicationController
  before_action :authenticate_request!

  skip_before_action :verify_authenticity_token

  respond_to :json

  def index
    render json: @current_site.email_campaigns,
      each_serializer: EmailCampaignSerializer
  end

  def show
    email_campaign = @current_site.email_campaigns.find params[:id]
    render json: EmailCampaignSerializer.new(email_campaign)
  end

  def create
    email_campaign = @current_site.email_campaigns.build email_campaign_params

    if email_campaign.save
      render json: EmailCampaignSerializer.new(email_campaign)
    else
      render json: { errors: email_campaign.errors.full_messages },
        status: :unprocessable_entity
    end
  end

  def update
    email_campaign = @current_site.email_campaigns.find(params[:id])

    if email_campaign.update(email_campaign_params)
      render json: EmailCampaignSerializer.new(email_campaign)
    else
      render json: { errors: email_campaign.errors.full_messages },
        status: :unprocessable_entity
    end
  end

  private

  def authenticate_request!
    @current_site = Site.find payload_site_id
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    render json: { errors: ['Unauthorized'] },
      status: :unauthorized
  end

  def payload_site_id
    payload[:site_id]
  end

  def payload
    JsonWebToken.decode auth_token
  end

  def auth_token
    request.headers['Authorization'].to_s.split.last
  end

  def email_campaign_params
    params
      .require(:email_campaign)
      .permit :contact_list_id, :name, :from_name, :from_email, :subject, :body
  end
end
