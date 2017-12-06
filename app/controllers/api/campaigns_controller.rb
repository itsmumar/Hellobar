class Api::CampaignsController < Api::BaseController
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

  def email_campaign_params
    params
      .require(:email_campaign)
      .permit :contact_list_id, :name, :from_name, :from_email, :subject, :body
  end
end
