class EmailCampaignsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_pro_managed_subscription
  before_action :load_site
  before_action :load_email_campaign, only: %i[edit update]

  def index
    @email_campaigns = @site.email_campaigns
  end

  private

  def load_email_campaign
    @email_campaign = @site.email_campaigns.find params[:id]
  end
end
