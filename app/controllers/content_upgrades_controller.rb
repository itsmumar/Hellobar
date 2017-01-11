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
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "file_name"   # Excluding ".pdf" extension.
      end
    end
  end

  def create
    @content_upgrade = SiteElement.create!(content_upgrade_params)

    flash[:success] = "Your content upgrade has been saved."
    redirect_to site_content_upgrades_path(@site.id)
  end

  def update
    @content_upgrade.update_attributes!(content_upgrade_params)

    flash[:success] = "Your content upgrade has been saved."
    redirect_to site_content_upgrades_path(@site.id)
  end

  def destroy
  end

  def style_editor
  end

  def update_styles
  end

  private

  def content_upgrade_params
    {
      type: 'ContentUpgrade',
      element_subtype: 'announcement',
      offer_text: params[:offer_text],
      offer_headline: params[:offer_headline],
      headline: params[:headline],
      caption: params[:caption],
      disclaimer: params[:disclaimer],
      content: params[:content],
      link_text: params[:button_text],
      name_placeholder: params[:name_placeholder],
      email_placeholder: params[:email_placeholder],
      rule: @site.rules.first
    }
  end

  def load_site
    super
  rescue ActiveRecord::RecordNotFound
    if request.get? or request.delete?
      head :not_found
    else
      head :forbidden
    end
  end

  def verify_capability
    unless @site && @site.capabilities.content_upgrades?
      render :json => { error: "forbidden" }, :status => :forbidden
    end
  end

  def load_content_upgrade
    @content_upgrade = @site.site_elements.find(params[:id])
    if @content_upgrade.rule.site_id != @site.id
      render :json => { error: "forbidden" }, :status => :forbidden
    end

  end
end
