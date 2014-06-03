class SitesController < ApplicationController
  before_filter :authenticate_user!
  layout "with_sidebar"

  def create
    @site = Site.new(site_params)

    if @site.valid?
      @site.save!
      SiteMembership.create!(:site => @site, :user => current_user)
    else
      render_action :new
    end

    redirect_to site_path(@site)
  end

  def new
    @site = Site.new
  end


  private

  def site_params
    params.require(:site).permit(:url)
  end
end
