class Api::CampaignsController < Api::ApplicationController
  before_action :find_campaign, only: %i[show update send_out]

  def index
    render json: @current_site.campaigns,
      each_serializer: CampaignSerializer
  end

  def show
    render json: CampaignSerializer.new(@campaign)
  end

  def create
    campaign = @current_site.campaigns.build campaign_params

    if campaign.save
      render json: CampaignSerializer.new(campaign)
    else
      render json: { errors: campaign.errors.full_messages },
        status: :unprocessable_entity
    end
  end

  def update
    if @campaign.update(campaign_params)
      render json: CampaignSerializer.new(@campaign)
    else
      render json: { errors: @campaign.errors.full_messages },
        status: :unprocessable_entity
    end
  end

  def send_out
    SendCampaign.new(@campaign).call
    render json: { message: 'Campaign successfully sent.' }
  end

  private

  def find_campaign
    @campaign = @current_site.campaigns.find(params[:id])
  end

  def campaign_params
    params
      .require(:campaign)
      .permit :contact_list_id, :name, :from_name, :from_email, :subject, :body
  end
end
