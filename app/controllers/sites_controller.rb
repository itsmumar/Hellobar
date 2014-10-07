class SitesController < ApplicationController
  include SitesHelper

  before_action :authenticate_user!, :except => :create
  before_action :load_site, :only => [:show, :edit, :update, :destroy, :install, :preview_script, :script, :improve, :chart_data]
  before_action :get_suggestions, :only => :improve
  before_action :get_top_performers, :only => :improve

  skip_before_action :verify_authenticity_token, :only => [:preview_script, :script]

  layout :determine_layout

  def new
    @site = Site.new
  end

  def create
    @site = Site.new(site_params)

    if current_user
      create_for_logged_in_user
    else
      create_for_temporary_user
    end
  end

  def edit
    @bills = @site.bills.includes(:subscription).select{|bill| bill.status == :paid }
    @next_bill = @site.bills.includes(:subscription).find{|bill| bill.status == :pending }
    @subscription = @site.current_subscription
    @payment_details = @subscription.payment_method.current_details if @subscription
  end

  def show
    redirect_to(action: "install") unless @site.has_script_installed?

    session[:current_site] = @site.id

    @totals = Hello::DataAPI.lifetime_totals_by_type(@site, @site.site_elements, 30, :force => is_page_refresh?)
    @recent_elements = @site.site_elements.where("site_elements.created_at > ?", 2.weeks.ago).order("created_at DESC")
  end

  def improve
    @totals = Hello::DataAPI.lifetime_totals_by_type(@site, @site.site_elements, @site.capabilities.num_days_improve_data, :force => is_page_refresh?)
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

  # Returns the site's script
  def script
    render :js => @site.script_content(params[:compress].to_i == 1)
  end

  def chart_data
    raw_data = Hello::DataAPI.lifetime_totals_by_type(@site, @site.site_elements).try(:[], params[:type].to_sym) || []
    series = raw_data.map{|d| d[params[:type] == "total" ? 0 : 1]}
    days = [params[:days].to_i, series.count].min

    series_with_dates = (0..days-1).map do |i|
      {
        :date => (Date.today - days + i + 1).strftime("%-m/%d"),
        :value => series[i]
      }
    end

    render :json => series_with_dates, :root => false
  end

  private

  def site_params
    params.require(:site).permit(:url, :opted_in_to_email_digest, :timezone)
  end

  def load_site
    @site = current_user.sites.find(params[:id])
  end

  def determine_layout
    params[:action] == "preview_script" ? false : "application"
  end

  def generate_temporary_logged_in_user
    sign_in User.generate_temporary_user
  end

  def create_for_temporary_user
    if @site.save
      generate_temporary_logged_in_user

      SiteMembership.create!(:site => @site, :user => current_user)

      @site.create_default_rule
      @site.generate_script

      redirect_to new_site_site_element_path(@site)
    else
      flash[:error] = "Your URL is not valid. Please double-check it and try again."
      redirect_to root_path
    end
  end

  def create_for_logged_in_user
    if @site.save
      SiteMembership.create!(:site => @site, :user => current_user)

      @site.create_default_rule
      @site.generate_script

      redirect_to new_site_site_element_path(@site)
    else
      flash.now[:error] = "There was a problem creating your site."
      render :action => :new
    end
  end

  def get_suggestions
    @suggestions = {}
    max = @site.capabilities.max_suggestions

    %w(all social email traffic).each do |name|
      @suggestions[name] = {}
      raw_suggestions = ImproveSuggestion.get(@site, name) || {}

      raw_suggestions.each do |k, v|
        @suggestions[name][k] = v[0, max]
      end
    end
  end

  def get_top_performers
    @top_performers = {}
    all_elements = @site.site_elements.sort_by{|e| -1 * e.conversion_percentage}

    %w(all social email traffic).each do |name|
      if name == "all"
        elements = all_elements
      else
        elements = all_elements.select { |e| e.short_subtype == name }
      end

      @top_performers[name] = elements[0,6]
    end
  end
end
