class CampaignsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_pro_managed_subscription
  before_action :load_site
  before_action :load_contact_lists, only: %i[new create edit update]
  before_action :load_campaign, only: %i[show edit update send_out]

  def index
    flash.now[:notice] = <<~NOTICE
      This is an exeprimental feature, still in its infancy. It will send out
      email campaign only to the 3 latest subscribers of a contact list.
    NOTICE

    @campaigns = @site.campaigns
  end

  def show
  end

  def new
    body = "<html>\n<p>Write your message here</p>\n</html>"
    @campaign = @site.campaigns.build body: body
  end

  def create
    @campaign = @site.campaigns.build campaign_params

    if @campaign.save
      flash[:success] = 'Campaign successfully created.'
      redirect_to site_campaign_path @site, @campaign
    else
      flash.now[:error] = @campaign.errors.full_messages
      render :new
    end
  end

  def edit
  end

  def update
    if @campaign.update campaign_params
      flash[:success] = 'Campaign successfully updated.'
      redirect_to site_campaign_path @site, @campaign
    else
      flash.now[:error] = @campaign.errors.full_messages
      render :edit
    end
  end

  def send_out
    SendCampaign.new(@campaign).call

    flash[:success] = 'Campaign successfully sent.'

    redirect_to site_campaigns_path @site
  end

  private

  def load_contact_lists
    @contact_lists = @site.contact_lists
  end

  def load_campaign
    @campaign = @site.campaigns.find params[:id]
  end

  def campaign_params
    params
      .require(:campaign)
      .permit :contact_list_id, :name, :from_name, :from_email, :subject, :body
  end
end
