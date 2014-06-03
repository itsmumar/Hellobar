class SitesController < ApplicationController
  layout :get_layout
  before_filter :authenticate_user!

  def create
    @site = Site.new(site_params)

    if @site.valid?
      @site.save!
      SiteMembership.create!(:site => @site, :user => current_user)
    end

    redirect_to site_path(@site)
  end


  private

  def get_layout
    params[:action] == "new" ? "application" : "with_sidebar"
  end

  def site_params
    params.require(:site).permit(:url)
  end
end
