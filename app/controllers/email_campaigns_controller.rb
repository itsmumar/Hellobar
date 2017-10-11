class EmailCampaignsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_pro_managed_subscription
  before_action :load_site
  before_action :load_contact_lists, only: %i[new create edit update]
  before_action :load_email_campaign, only: %i[show edit update]

  def index
    @email_campaigns = @site.email_campaigns
  end

  def show
  end

  def new
    @email_campaign = @site.email_campaigns.new
  end

  def create
    @email_campaign = @site.email_campaigns.new email_campaign_params

    if @email_campaign.save
      flash[:success] = 'Email Campaign successfully created.'
      redirect_to site_email_campaign_path @site, @email_campaign
    else
      flash.now[:error] = @email_campaign.errors.full_messages
      render :new
    end
  end

  def edit
  end

  def update
    if @email_campaign.update email_campaign_params
      flash[:success] = 'Email Campaign was successfully updated.'
      redirect_to site_email_campaign_path @site, @email_campaign
    else
      flash.now[:error] = @email_campaign.errors.full_messages
      render :edit
    end
  end

  private

  def load_contact_lists
    @contact_lists = @site.contact_lists
  end

  def load_email_campaign
    @email_campaign = @site.email_campaigns.find params[:id]
  end

  def email_campaign_params
    params
      .require(:email_campaign)
      .permit :contact_list_id, :name, :from_name, :from_email, :subject, :body
  end
end
