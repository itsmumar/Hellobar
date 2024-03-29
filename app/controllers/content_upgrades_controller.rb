class ContentUpgradesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site
  before_action :verify_capability
  before_action :load_content_upgrade, only: %i[show edit update destroy toggle_paused]

  def index
    @content_upgrades = @site.site_elements.content_upgrades.order(created_at: :desc)
    @content_upgrades = @content_upgrades.sort_by(&params[:sort].to_sym) if params[:sort]
    @content_upgrades = @content_upgrades.reverse if params[:desc].eql?('true')
  end

  def new
    @content_upgrade = ContentUpgrade.new
    @styles = @site.content_upgrade_styles

    # Some Defualts
    @content_upgrade.name_placeholder = 'First Name'
    @content_upgrade.email_placeholder = 'Your Email'
    @content_upgrade.link_text = 'Download Now'
    @content_upgrade.headline = 'Enter your email to download this free guide right now.'
    @content_upgrade.caption = 'Almost there! Please complete this form and click the button below to gain instant access.'
    @content_upgrade.content_upgrade_settings.disclaimer = 'We hate SPAM and promise to keep your email address safe.'
  end

  def show
    render :show
  end

  def edit
    @styles = @site.content_upgrade_styles
  end

  def create
    @content_upgrade = ContentUpgrade.new(content_upgrade_params)

    if @content_upgrade.save
      @site.script.generate
      flash[:success] = 'Your content upgrade has been saved.'
      redirect_to site_content_upgrades_path(@site.id)
    else
      flash.now[:error] = @content_upgrade.errors.full_messages
      @styles = @site.content_upgrade_styles

      render :new
    end
  end

  def update
    if @content_upgrade.update(content_upgrade_params)
      @site.script.generate
      flash[:success] = 'Your content upgrade has been saved.'
      redirect_to site_content_upgrades_path(@site.id)
    else
      flash.now[:error] = @content_upgrade.errors.full_messages
      @styles = @site.content_upgrade_styles

      render :edit
    end
  end

  def style_editor
    @styles = @site.content_upgrade_styles
  end

  def update_styles
    @styles = @site.content_upgrade_styles

    if @styles.update(styles_params)
      @site.script.generate
      flash[:success] = 'Content Upgrade styles have been saved.'
      redirect_to site_content_upgrades_path(@site.id)
    else
      render :style_editor
    end
  end

  def destroy
    @content_upgrade.destroy!
    flash[:success] = 'Your content upgrade has been deleted.'
    redirect_to site_content_upgrades_path(@site.id)
  end

  def toggle_paused
    @content_upgrade.toggle_paused!
    @site.script.generate
    redirect_to site_content_upgrades_path(@site.id)
  end

  private

  def content_upgrade_params
    {
      type: 'ContentUpgrade',
      element_subtype: 'email',
      headline: params[:headline],
      caption: params[:caption],
      link_text: params[:link_text],
      name_placeholder: params[:name_placeholder],
      email_placeholder: params[:email_placeholder],
      contact_list_id: params[:contact_list_id],
      rule: @site.rules.first,
      enable_gdpr: ActiveRecord::Type::Boolean.new.type_cast_from_user(params[:enable_gdpr]),
      content_upgrade_settings_attributes: {
        id: params[:content_upgrade_settings_id],
        offer_headline: params[:offer_headline],
        disclaimer: params[:disclaimer],
        content_upgrade_title: params[:content_upgrade_title],
        content_upgrade_url: params[:content_upgrade_url],
        thank_you_enabled: params[:thank_you_enabled].present?,
        thank_you_headline: params[:thank_you_headline],
        thank_you_subheading: params[:thank_you_subheading],
        thank_you_cta: params[:thank_you_cta],
        thank_you_url: params[:thank_you_url]
      }.merge(pdf_params)
    }
  end

  def styles_params
    params.require(:content_upgrade_styles).permit(
      :offer_bg_color,
      :offer_text_color,
      :offer_link_color,
      :offer_border_color,
      :offer_border_width,
      :offer_border_style,
      :offer_border_radius,
      :modal_button_color,
      :offer_font_size,
      :offer_font_weight,
      :offer_font_family_name
    )
  end

  def pdf_params
    return {} unless params[:content_upgrade]
    params.require(:content_upgrade).permit(:content_upgrade_pdf)
  end

  def load_site
    super
  rescue ActiveRecord::RecordNotFound
    if request.get? || request.delete?
      head :not_found
    else
      head :forbidden
    end
  end

  def verify_capability
    return if @site&.capabilities&.content_upgrades?

    error_response(:forbidden)
  end

  def load_content_upgrade
    @content_upgrade = @site.site_elements.find(params[:id])
    return unless @content_upgrade.rule.site_id != @site.id

    error_response(:forbidden)
  end
end
