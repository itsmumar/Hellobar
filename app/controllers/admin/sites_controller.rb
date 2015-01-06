class Admin::SitesController < ApplicationController
  include Subscribable
  layout "admin"

  before_action :require_admin

  def update
    begin
      update_subscription(site, nil, subscription_params)
      flash[:success] = "Changed subscription of #{site.url} to #{site.current_subscription.values[:name]}"
    rescue => e
      flash[:error] = "There was an error trying to update the subscription: #{e.message}"
    end

    redirect_to admin_user_path(params[:user_id])
  end

  private
  def subscription_params
    params.require(:subscription).permit(:plan, :schedule, :trial_period)
  end

  def site
    @site ||= Site.find(params[:id])
  end
end
