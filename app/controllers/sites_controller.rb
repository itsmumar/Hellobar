class SitesController < ApplicationController
  include SitesHelper

  before_action :generate_temporary_logged_in_user, only: :create
  before_action :authenticate_user!
  before_action :load_site, :only => [:show, :edit, :update, :destroy, :preview_script]

  skip_before_action :verify_authenticity_token, :only => :preview_script

  layout :determine_layout

  def create
    @site = Site.new(site_params)

    if @site.save
      SiteMembership.create!(:site => @site, :user => current_user)

      @site.create_default_rule
      @site.generate_script

      flash[:success] = "Your site was successfully created."

      redirect_to next_step
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
    @totals = get_rolled_up_totals(@site)
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

  def generate_temporary_logged_in_user
    unless current_user
      @user = User.generate_temporary_user

      sign_in @user
    end
  end

  def next_step
    # if coming from the root url '/', go to the editor
    if request.referrer == root_url
      new_site_site_element_path(@site)
    else # Site#show
      site_path(@site)
    end
  end

  def get_rolled_up_totals(site)
    data = Hello::DataAPI.lifetime_totals(site, site.site_elements) || {}

    {:total => [0, 0], :email => [0, 0], :social => [0, 0], :traffic => [0, 0]}.tap do |totals|
      data.each do |k, v|
        if element = site.site_elements.find(k)
          views, conversions = v[0]

          totals[:total][0] += views
          totals[:total][1] += conversions

          key = case element.element_subtype
                when "email" then :email
                when "traffic" then :traffic
                when /social\// then :social
                end

          totals[key][0] += views
          totals[key][1] += conversions
        end
      end
    end
  end
end
