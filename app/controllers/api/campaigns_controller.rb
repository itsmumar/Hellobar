class Api::CampaignsController < Api::ApplicationController
  before_action :find_campaign, only: %i[show update send_out]

  def index
    render json: @current_site.email_campaigns,
      each_serializer: EmailCampaignSerializer
  end

  def show
    render json: EmailCampaignSerializer.new(@email_campaign)
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
    if @email_campaign.update(email_campaign_params)
      render json: EmailCampaignSerializer.new(@email_campaign)
    else
      render json: { errors: @email_campaign.errors.full_messages },
        status: :unprocessable_entity
    end
  end

  def send_out
    SendEmailCampaign.new(@email_campaign).call
    render json: { message: 'Email Campaign successfully sent.' }
  end

  private

  def find_campaign
    @email_campaign = @current_site.email_campaigns.find(params[:id])
  end

  def email_campaign_params
    params
      .require(:email_campaign)
      .permit :contact_list_id, :name, :from_name, :from_email, :subject, :body
  end
end
