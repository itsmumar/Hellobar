class Api::CampaignsController < Api::ApplicationController
  before_action :find_campaign, except: %i[index create]

  rescue_from Campaign::InvalidTransition, with: :handle_error

  def index
    campaigns, statistics = FilterCampaigns.new(@current_site, params).call

    data = {
      campaigns: campaigns.map { |campaign| CampaignSerializer.new(campaign) },
      statistics: statistics
    }

    render json: data
  end

  def show
    render json: CampaignSerializer.new(@campaign)
  end

  def create
    campaign = @current_site.campaigns.build campaign_params

    if campaign.save
      render json: CampaignSerializer.new(campaign)
    else
      render json: { errors: campaign.errors.messages },
        status: :unprocessable_entity
    end
  end

  def update
    UpdateCampaign.new(@campaign, campaign_params).call
    render json: CampaignSerializer.new(@campaign)
  end

  def send_out
    SendCampaign.new(@campaign).call
    render json: CampaignSerializer.new(@campaign)
  end

  def send_out_test_email
    SendTestEmailForCampaign.new(@campaign, params[:contacts]).call
    render json: { message: 'Test email successfully sent.' }
  end

  def archive
    @campaign.archived!
    render json: CampaignSerializer.new(@campaign)
  end

  def destroy
    @campaign.destroy
    render json: { message: 'Campaign successfully deleted.' }
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
