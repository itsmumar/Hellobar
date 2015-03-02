class SiteElementsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site
  before_action :load_site_element, :only => [:show, :edit, :update, :destroy, :toggle_paused]

  layout :determine_layout

  def show
    render :json => @site_element, serializer: SiteElementSerializer
  end

  def index
    # force cache miss if user is refreshing the page to check if their script is installed and working
    @site.lifetime_totals(force: true) if is_page_refresh?

    @rules = @site.rules.includes(:conditions)
  end

  def new
    if current_user.temporary? && @site.site_elements.any?
      return redirect_to after_sign_in_path_for(@site)
    end

    @rules = @site.rules.all
    @site_element = @site.site_elements.new(:rule => @site.rules.first)

    respond_to do |format|
      format.html
      format.json { render :json => @site_element, serializer: SiteElementSerializer }
    end
  end

  def edit
    @rules = @site.rules.all
  end

  def create
    @site_element = SiteElement.new(site_element_params)

    if @site_element.valid?
      @site_element.save!
      @site.generate_script
      render :json => @site_element, serializer: SiteElementSerializer
    else
      render :json => @site_element, :status => :unprocessable_entity, serializer: SiteElementSerializer
    end
  end

  def update
    if @site_element.update_attributes(site_element_params)
      @site.generate_script
      render :json => @site_element, serializer: SiteElementSerializer
    else
      render :json => @site_element, :status => :unprocessable_entity, serializer: SiteElementSerializer
    end
  end

  def destroy
    @site_element.destroy
    @site.generate_script

    respond_to do |format|
      format.js { head :ok }
      format.html do
        flash[:success] = "Your bar was successfully deleted."
        redirect_to site_site_elements_path(:site_id => @site)
      end
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
    super
    session[:current_site] = @site.id if @site
  end

  def determine_layout
    %w(new edit).include?(action_name) ? "ember" : "application"
  end

  def load_site_element
    @site_element = @site.site_elements.find(params[:id])
  end

  def site_element_params
    settings_keys = [:url, :collect_names, :url_to_tweet, :message_to_tweet, :twitter_handle, :url_to_like, :url_to_share, :url_to_plus_one, :pinterest_url, :pinterest_image_url, :pinterest_description, :pinterest_user_url, :pinterest_full_name, :buffer_url, :buffer_message, :use_location_for_url, :display_when_scroll_percentage, :display_when_scroll_element, :display_when_scroll_type, :display_when_delay, :display_when_delay_units]

    params.require(:site_element).permit(:type, :rule_id, :element_subtype, :headline, :background_color, :border_color, :button_color, :font, :link_color, :link_text, :text_color, :closable, :show_branding, :contact_list_id, :display_when, :thank_you_text, :remains_at_top, :pushes_page_down, :open_in_new_window, :size, :animated, :wiggle_button, {:settings => settings_keys})
  end
end
