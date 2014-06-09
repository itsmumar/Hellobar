class SitesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site, :only => [:show, :edit, :update, :wordpress_plugin]

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

  def update
    if @site.update_attributes(site_params)
      flash[:success] = "Your settings have been updated."
      redirect_to site_path(@site)
    else
      flash.now[:error] = "There was a problem updating your settings."
      render :action => :edit
    end
  end


  private

  def site_params
    params.require(:site).permit(:url, :opted_in_to_email_digest)
  end

  def load_site
    @site = current_user.sites.find(params[:id])
  end
end
