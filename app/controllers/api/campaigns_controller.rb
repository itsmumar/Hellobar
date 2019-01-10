class Api::CampaignsController < Api::ApplicationController
  before_action :find_campaign, except: %i[index create upload_image_froala]
  before_action :validate_sender_address, only: %i[send_out send_out_test_email]
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

  def upload_image_froala
    if params[:file]
      @image_url = UploadImageToS3.new(photo: params.require(:file)).call
      return render json: { link: @image_url }.to_json
    end
    render json: { link: nil }.to_json
  end

  private

  def validate_sender_address
    render json: { message: 'Please fill Physical Address in settings before sending a campaign' }, status: :unprocessable_entity if site.sender_address.blank?
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
