class Api::CampaignsController < Api::ApplicationController
  before_action :find_campaign, except: %i[index create]
  before_action :validate_sender_address, :verify_is_spammer, only: %i[send_out send_out_test_email]

  rescue_from Campaign::InvalidTransition, with: :handle_error

  def index
    campaigns, statistics = FilterCampaigns.new(site, params).call

    data = {
      campaigns: campaigns.map { |campaign| CampaignSerializer.new(campaign) },
      statistics: statistics
    }

    render json: data
  end

  def show
    render json: @campaign
  end

  def create
    @campaign = site.campaigns.build(campaign_params)
    @campaign.save!

    render json: @campaign
  end

  def update
    UpdateCampaign.new(@campaign, campaign_params).call

    render json: @campaign
  end

  def send_out
    SendCampaign.new(@campaign).call

    render json: @campaign
  end

  def send_out_test_email
    SendTestEmailForCampaign.new(@campaign, params[:contacts]).call

    render json: { message: 'Test email successfully sent.' }
  end

  def archive
    @campaign.archived!

    render json: @campaign
  end

  def destroy
    @campaign.destroy

    render json: { message: 'Campaign successfully deleted.' }
  end

  private

  def validate_sender_address
    render json: { message: 'Please fill Physical Address in settings before sending a campaign' }, status: :unprocessable_entity if site.sender_address.blank?
  end

  def verify_is_spammer
    render json: { message: 'You can not send a campaign anymore since one of your previous campaigns have been marked as spam, Please contact support for more details' }, status: :unprocessable_entity if current_user.spammer?
  end

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def find_campaign
    @campaign = site.campaigns.find(params[:id])
  end

  def campaign_params
    params
      .require(:campaign)
      .permit :contact_list_id, :email_id, :name
  end
end
