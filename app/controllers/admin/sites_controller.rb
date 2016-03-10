class Admin::SitesController < ApplicationController
  include Subscribable
  layout "admin"

  before_action :require_admin

  def update
    begin
      site.update_attributes(site_params)
      flash[:success] = "Site and/or subscription has been updated."
    rescue => e
      flash[:error] = "Error: #{e.message}"
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

    def site_params
      params.require(:site).permit(:id, :url, :opted_in_to_email_digest, :timezone, :invoice_information,
                    subscription: [:plan, :schedule, :trial_period])
    end


    def site
      @site ||= Site.find(params[:id])
    end
end
