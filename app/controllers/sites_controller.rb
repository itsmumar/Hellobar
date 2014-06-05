class SitesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site, :only => :show

  layout "with_sidebar"

  def create
    @site = Site.new(site_params)

    if @site.valid?
      @site.save!
      SiteMembership.create!(:site => @site, :user => current_user)
      flash[:success] = "Your site was successfully created."
      redirect_to site_path(@site)
    else
      flash.now[:error] = "There was a problem creating your site."
      render :action => :new
    end
  end

  def new
    @site = Site.new
  end

  def show
    session[:current_site] = @site.id
  end


  private

  def site_params
    params.require(:site).permit(:url)
  end

  def load_site
    @site = current_user.sites.find(params[:id])
  end
end
