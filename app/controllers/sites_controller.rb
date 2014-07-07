class SitesController < ApplicationController
  include SitesHelper

  before_filter :authenticate_user!
  before_filter :load_site, :only => [:show, :edit, :update, :destroy, :preview_script]

  skip_before_filter :verify_authenticity_token, :only => :preview_script

  layout :determine_layout

  def create
    @site = Site.new(site_params)

    if @site.save
      SiteMembership.create!(:site => @site, :user => current_user)

      @site.create_default_rule
      @site.generate_script

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

  def destroy
    @site.destroy
    flash[:success] = "Your site has been successfully deleted"

    redirect_to(current_site ? site_path(current_site) : new_site_path)
  end

  # a version of the site's script with all templates, no elements and no rules, for use in the editor live preview
  def preview_script
    generator = ScriptGenerator.new(@site, :templates => SiteElement::BAR_TYPES, :rules => [])
    render :js => generator.generate_script
  end

  private

  def site_params
    params.require(:site).permit(:url, :opted_in_to_email_digest)
  end

  def load_site
    @site = current_user.sites.find(params[:id])
  end

  def determine_layout
    params[:action] == "preview_script" ? false : "application"
  end
end
