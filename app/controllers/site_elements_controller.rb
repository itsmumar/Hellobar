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

    @rules = @site.rules.includes([:site_elements, :conditions])
  end

  def new
    if current_user.temporary? && @site.site_elements.any?
      return redirect_to after_sign_in_path_for(@site)
    end

    @rules = @site.rules.all
    @site_element = @site.site_elements.new({
      rule: @site.rules.first,
      show_branding: !@site.capabilities(true).remove_branding?,
      settings: {url: @site.url, url_to_like: @site.url }
    })

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
      render :json => @site_element, serializer: SiteElementSerializer
    else
      render :json => @site_element, :status => :unprocessable_entity, serializer: SiteElementSerializer
    end
  end

  def update
    updater = UpdateSiteElement.new(@site_element)
    if updater.update(site_element_params)
      render :json => updater.element, serializer: SiteElementSerializer
    else
      render :json => @site_element, :status => :unprocessable_entity, serializer: SiteElementSerializer
    end
  end

  def destroy
    @site_element.destroy

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
    params.require(:site_element).permit(
      :active_image_id,
      :animated,
      :background_color,
      :border_color,
      :button_color,
      :caption,
      :closable,
      :contact_list_id,
      :display_when,
      :element_subtype,
      :email_placeholder,
      :font,
      :headline,
      :image_placement,
      :link_color,
      :link_text,
      :name_placeholder,
      :open_in_new_window,
      :placement,
      :pushes_page_down,
      :remains_at_top,
      :rule_id,
      :show_branding,
      :size,
      :text_color,
      :thank_you_text,
      :type,
      :view_condition_attribute,
      :view_condition,
      :wiggle_button,
      {:settings => settings_keys}
    )
  end

  def settings_keys
    [
      :buffer_url,
      :buffer_message,
      :collect_names,
      :display_when_scroll_percentage,
      :display_when_scroll_element,
      :display_when_scroll_type,
      :display_when_delay,
      :display_when_delay_units,
      :message_to_tweet,
      :pinterest_url,
      :pinterest_image_url,
      :pinterest_description,
      :pinterest_user_url,
      :pinterest_full_name,
      :after_email_submit_action,
      :redirect_url,
      :twitter_handle,
      :url,
      :url_to_like,
      :url_to_plus_one,
      :url_to_share,
      :url_to_tweet,
      :use_location_for_url,
    ]
  end
end
