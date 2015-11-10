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

  def regenerate
    site = Site.where(id: params[:id]).try(:first)

    if site.nil?
      render json: { message: "Site was not found" }, status: 404 and return
    end

    begin
      site.generate_script(immediately: true)
      render json: {  message: "Site regenerated" }, status: 200
    rescue RuntimeError
      render json: {
        message: "Site's script failed to generate"
      },
      status: 500
    end
  end

  private
  def subscription_params
    params.require(:subscription).permit(:plan, :schedule, :trial_period)
  end

  def site
    @site ||= Site.find(params[:id])
  end
end
