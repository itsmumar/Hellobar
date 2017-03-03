class ContentUpgradesController < ApplicationController
  include RulesHelper

  before_action :authenticate_user!
  before_action :load_site
  before_action :verify_capability, only: [:create, :update]
  before_action :load_content_upgrade, only: [:show, :edit, :update, :destroy]

  def index
    @content_upgrades = @site.site_elements.active_content_upgrades
  end

  def new
    @content_upgrade = SiteElement.new
    @styles = @site.get_content_upgrade_styles
    # Some Defualts
    @content_upgrade.name_placeholder = 'First Name'
    @content_upgrade.email_placeholder = 'Your Email'
    @content_upgrade.disclaimer = 'We hate SPAM and promise to keep your email address safe.'
    @content_upgrade.link_text = 'Download Now'
    @content_upgrade.headline = 'Enter your email to download this free guide right now.'
    @content_upgrade.caption = 'Almost there! Please complete this form and click the button below to gain instant access.'
  end

  def edit
    @styles = @site.get_content_upgrade_styles
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "content_upgrade_#{id}" # Excluding ".pdf" extension.
      end
    end
  end

  def create
    @content_upgrade = SiteElement.create!(content_upgrade_params)

    flash[:success] = 'Your content upgrade has been saved.'
    redirect_to site_content_upgrades_path(@site.id)
  end

  def update
    @content_upgrade.update_attributes!(content_upgrade_params)

    flash[:success] = 'Your content upgrade has been saved.'
    redirect_to site_content_upgrades_path(@site.id)
  end

  def destroy; end

  def style_editor
    @styles = @site.get_content_upgrade_styles
  end

  def update_styles
    style_params = {
      offer_bg_color: params[:offer_bg_color],
      offer_text_color: params[:offer_text_color],
      offer_link_color: params[:offer_link_color],
      offer_border_color: params[:offer_border_color],
      offer_border_width: params[:offer_border_width],
      offer_border_style: params[:offer_border_style],
      offer_border_radius: params[:offer_border_radius],
      modal_button_color: params[:modal_button_color]
    }

    @site.update_content_upgrade_styles!(style_params)

    flash[:success] = 'Content Upgrade styles have been saved.'
    redirect_to site_content_upgrades_path(@site.id)
  end

  private

  def content_upgrade_params
    {
      type: 'ContentUpgrade',
      element_subtype: 'email',
      offer_text: params[:offer_text],
      offer_headline: params[:offer_headline],
      headline: params[:headline],
      caption: params[:caption],
      disclaimer: params[:disclaimer],
      content: params[:content],
      link_text: params[:link_text],
      name_placeholder: params[:name_placeholder],
      email_placeholder: params[:email_placeholder],
      contact_list_id: params[:contact_list_id],
      rule: @site.rules.first
    }
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
    unless @site && @site.capabilities.content_upgrades?
      render json: { error: 'forbidden' }, status: :forbidden
    end
  end

  def load_content_upgrade
    @content_upgrade = @site.site_elements.find(params[:id])
    if @content_upgrade.rule.site_id != @site.id
      render json: { error: 'forbidden' }, status: :forbidden
    end
  end
end
