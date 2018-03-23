class SitesController < ApplicationController
  include SitesHelper

  before_action :authenticate_user!, except: :create
  before_action :load_site, except: %i[index new create]
  before_action :load_top_performers, only: :improve
  before_action :load_bills, only: :edit

  skip_before_action :verify_authenticity_token, only: %i[preview_script script]

  layout :determine_layout

  def index
  end

  def new
    @site = Site.new(url: params[:url])

    flash.now[:notice] = "Are you sure you want to add the site #{ @site.url }?" if params[:url]
  end

  def create
    @site = Site.new(site_params)
    cookies.permanent[:registration_url] = @site.url

    if current_user
      create_for_logged_in_user
    else
      session[:new_site_url] = @site.url
      session[:promotional_code] = params[:promotional_code]
      validate_and_redirect_to_google_auth
    end
  end

  def edit
  end

  def show
    # Store last site viewed
    cookies[:lsv] = @site.id

    respond_to do |format|
      format.html do
        redirect_to(action: 'install') unless @site.script_installed?

        flash[:success] = 'Script successfully installed.' if params[:installed]
        session[:current_site] = @site.id

        @totals = site_statistics
        @recent_elements = @site.site_elements.active.recent(5)
      end

      format.json { render json: @site }
    end
  end

  def improve
    @totals = site_statistics
  end

  def update
    if @site.update_attributes(site_params)
      @site.script.generate
      flash[:success] = 'Your settings have been updated.'
      redirect_to site_path(@site)
    else
      load_bills
      flash.now[:error] = @site.errors.full_messages
      render action: :edit
    end
  end

  def destroy
    DestroySite.new(@site).call
    flash[:success] = 'Your site has been successfully deleted'

    redirect_to(current_site ? site_path(current_site) : new_site_path)
  end

  # a version of the site's script with all templates, no elements and no rules, for use in the editor live preview
  def preview_script
    GenerateStaticScriptModules.new.call if Rails.env.test? || Rails.env.development?
    render js: render_script(preview: true)
  end

  # Returns the site's script
  def script
    render js: render_script(preview: false)
  end

  def chart_data
    json = ChartDataSerializer.new(site_statistics, params).as_json
    render json: json, root: false
  end

  def downgrade
    ChangeSubscription.new(@site, subscription: 'free', schedule: 'monthly').call
    redirect_to site_path(@site)
  end

  def install
  end

  def install_redirect
    redirect_to site_install_path(current_site)
  end

  # async installation check, but will respond instantly with a not-up-to-date info
  def install_check
    CheckStaticScriptInstallation.new(@site).call

    render json: { script_installed: @site.script_installed? }
  end

  private

  def site_statistics
    @site_statistics ||=
      FetchSiteStatistics.new(@site, days_limit: @site.capabilities.num_days_improve_data).call
  end

  def site_params
    if session[:new_site_url]
      params[:site] ||= {}
      params[:site][:url] ||= session.delete(:new_site_url)
    end
    params.require(:site).permit(:url, :opted_in_to_email_digest, :timezone, :invoice_information)
  end

  # overwrite where we get the params from from ApplicationController
  def load_site
    @site ||= current_user.sites.find(params[:id]) if current_user && params[:id]
  end

  def determine_layout
    params[:action] == 'preview_script' ? false : 'application'
  end

  def create_for_logged_in_user
    CreateSite.new(
      @site,
      current_user,
      referral_token: session[:referral_token],
      promotional_code: session[:promotional_code]
    ).call

    redirect_to new_site_site_element_path(@site)
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:error] = e.record.errors.full_messages
    render action: :new
  rescue CreateSite::DuplicateURLError => e
    flash[:error] = e.message
    return redirect_to site_path(e.existing_site)
  end

  def validate_and_redirect_to_google_auth
    if !@site.valid?
      flash[:error] = 'Your URL is not valid. Please double-check it and try again.'
      redirect_to root_path
    elsif params[:source] == 'landing' && Site.by_url(@site.url).any?
      redirect_to new_user_session_path(existing_url: @site.url)
    else
      session[:new_site_url] = @site.url
      redirect_to '/auth/google_oauth2'
    end
  end

  def load_top_performers
    @top_performers = {}
    all_elements = @site.site_elements.sort_by { |e| -1 * e.conversion_percentage }

    %w[all social email traffic call].each do |name|
      elements =
        if name == 'all'
          all_elements
        else
          all_elements.select { |e| e.short_subtype == name }
        end

      @top_performers[name] = elements[0, 6]
    end
  end

  def load_bills
    @bills = @site.bills.paid_or_failed.non_free.includes(:subscription).reorder(bill_at: :desc)
    @next_bill = @site.bills.pending.includes(:subscription).last
  end

  def render_script(preview:)
    options =
      if preview
        { templates: SiteElement.all_templates, no_rules: true, preview: true, compress: false }
      else
        { compress: params[:compress].to_i == 1 }
      end

    RenderStaticScript.new(@site, **options).call
  end
end
