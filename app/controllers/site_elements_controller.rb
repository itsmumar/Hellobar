class SiteElementsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site
  before_filter :load_site_element, :only => [:show, :edit, :update, :destroy, :toggle_paused]

  layout :determine_layout

  def show
    render :json => @site_element
  end

  def index
    @rules = @site.rules.includes(:conditions)
    @totals = Hello::DataAPI.lifetime_totals(@site, @site.site_elements) || {}
  end

  def new
    @rules = @site.rules.all
    @rules << Rule.new(:id => 0)
    @site_element = @site.site_elements.new(:rule => @site.rules.first)

    respond_to do |format|
      format.html
      format.json { render :json => @site_element }
    end
  end

  def edit
    @rules = @site.rules.all
    @rules << Rule.new(:id => 0)
  end

  def create
    @site_element = SiteElement.new(site_element_params)

    if @site_element.valid?
      @site_element.save!
      @site.generate_script
      render :json => @site_element
    else
      render :json => @site_element, :status => :unprocessable_entity
    end
  end

  def update
    if @site_element.update_attributes(site_element_params)
      @site.generate_script
      render :json => @site_element
    else
      render :json => @site_element, :status => :unprocessable_entity
    end
  end

  def destroy
    @site_element.destroy
    @site.generate_script
    flash[:success] = "Your bar was successfully deleted."

    respond_to do |format|
      format.js { head :ok }
      format.html { redirect_to site_site_elements_path(:site_id => @site) }
    end
  end

  def toggle_paused
    @site_element.toggle_paused!
    @site.generate_script

    respond_to do |format|
      format.js { head :ok }
      format.html { redirect_to site_site_elements_path(:site_id => @site) }
    end
  end

  private

  def load_site
    @site = current_user.sites.find(params[:site_id])
  end

  def determine_layout
    %w(new edit).include?(action_name) ? "ember" : "application"
  end

  def load_site_element
    @site_element = @site.site_elements.find(params[:id])
  end

  def site_element_params
    settings_keys = [:url, :collect_names, :url_to_tweet, :message_to_tweet, :twitter_handle, :url_to_like, :url_to_share, :url_to_plus_one, :pinterest_url, :pinterest_image_url, :pinterest_description, :pinterest_user_url, :pinterest_full_name, :buffer_url, :buffer_message, :use_location_for_url]
    params.require(:site_element).permit(:rule_id, :element_subtype, :message, :background_color, :border_color, :button_color, :font, :link_color, :link_text, :text_color, :closable, :show_branding, :contact_list_id, {:settings => settings_keys})
  end
end
