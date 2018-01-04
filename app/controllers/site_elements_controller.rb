class SiteElementsController < ApplicationController
  before_action :authenticate_user!
  before_action :force_trailing_slash, only: %i[new edit]
  before_action :load_site
  before_action :load_site_element, only: %i[show edit update destroy toggle_paused]

  layout :determine_layout

  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity_error

  def show
    render json: @site_element, serializer: SiteElementSerializer
  end

  def index
    @rules = @site.rules.includes(%i[site_elements conditions])
  end

  def new
    if current_user.temporary? && @site.site_elements.any?
      return redirect_to after_sign_in_path_for(@site)
    end

    @rules = @site.rules.all
    @site_element = SiteElement.new(
      font_id: SiteElement.columns_hash['font_id'].default,
      rule: @site.rules.first,
      show_branding: !@site.capabilities.remove_branding?,
      closable: false,
      theme_id: 'autodetect',
      settings: { url: @site.url, url_to_like: @site.url }
    )

    respond_to do |format|
      format.html
      format.json { render json: @site_element, serializer: SiteElementSerializer }
    end
  end

  def edit
    @rules = @site.rules.all
  end

  def create
    site_element = CreateSiteElement.new(site_element_params, @site, current_user).call
    flash[:success] = message_to_clear_cache
    render json: site_element, serializer: SiteElementSerializer
  end

  def update
    site_element = UpdateSiteElement.new(@site_element, site_element_params).call
    flash[:success] = message_to_clear_cache
    render json: site_element, serializer: SiteElementSerializer
  end

  def destroy
    @site_element.destroy
    @site.script.generate

    respond_to do |format|
      format.js { head :ok }
      format.html do
        flash[:success] = 'Your bar was successfully deleted.'
        redirect_to site_site_elements_path(site_id: @site)
      end
    end
  end

  def toggle_paused
    @site_element.toggle_paused!
    @site.script.generate
    head :ok
  end

  private

  def unprocessable_entity_error(e)
    response = { errors: e.record.errors, full_error_messages: e.record.errors.to_a }
    render json: response, status: :unprocessable_entity
  end

  def message_to_clear_cache
    message = 'It may take a few minutes for Hello Bar to show up on your site. '
    message << 'You’ll want to <a href="http://www.refreshyourcache.com/en/home" target="_blank" style="text-decoration: underline;">clear your cache</a> to see your updates.'
  end

  def load_site
    super
    session[:current_site] = @site.id if @site
  end

  def determine_layout
    ['new', 'edit'].include?(action_name) ? 'ember' : 'application'
  end

  def force_trailing_slash
    url = if Rails.env.production? || Rails.env.staging? || Rails.env.edge?
            request.original_url.gsub(/\Ahttp:/, 'https:')
          else
            request.original_url
          end

    redirect_to url + '/' if request.format.html? && !request.original_url.match(/\/\z/)
  end

  def load_site_element
    @site_element = @site.site_elements.find(params[:id])
  end

  def site_element_params
    params.require(:site_element).permit(
      :active_image_id, :animated,
      :answer1, :answer1caption, :answer1link_text, :answer1response,
      :answer2, :answer2caption, :answer2link_text, :answer2response,
      :background_color, :border_color, :button_color, :content, :caption,
      :closable, :contact_list_id, :display_when, :element_subtype,
      :email_placeholder, :font_id, :headline, :image_placement, :image_opacity,
      :link_color, :link_text, :name_placeholder, :open_in_new_window,
      :phone_country_code, :phone_number, :placement, :pushes_page_down,
      :question, :remains_at_top, :rule_id, :show_branding, :size, :text_color,
      :thank_you_text, :theme_id, :type, :use_question,
      :view_condition_attribute, :view_condition, :wiggle_button,
      :use_default_image, :sound, :notification_delay, :trigger_color,
      :trigger_icon_color,
      { settings: settings_keys },
      blocks: blocks_keys
    )
  end

  def blocks_keys
    [
      :id,
      { content: %i[text href] },
      themes: [
        :id,
        :css_classes,
        { styles: %i[background_color border_color] }
      ]
    ]
  end

  def settings_keys
    [
      :after_email_submit_action, :buffer_message, :buffer_url,
      { fields_to_collect: %i[id type label is_enabled] },
      { cookie_settings: %i[duration success_duration] },
      :display_when_delay, :display_when_delay_units, :display_when_scroll_element,
      :display_when_scroll_percentage, :display_when_scroll_type,
      :message_to_tweet,
      :pinterest_description, :pinterest_full_name,
      :pinterest_image_url, :pinterest_url, :pinterest_user_url,
      :redirect_url, :twitter_handle,
      :url, :url_to_like, :url_to_plus_one, :url_to_share, :url_to_tweet,
      :use_location_for_url
    ]
  end
end
