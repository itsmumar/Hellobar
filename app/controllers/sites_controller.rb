class SitesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site, :only => :show

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

  def show
    session[:active_site] = @site.id
  end


  private

  def site_params
    params.require(:site).permit(:url)
  end

  def load_site
    @site = current_user.sites.find(params[:id])
  end
end
