class SitesController < ApplicationController
  include SitesHelper

  before_action :authenticate_user!
  before_action :load_site, except: %i[index new create]
  before_action :load_top_performers, only: :improve
  before_action :load_bills, only: :edit
  before_action :check_free_overage, only: %i[index improve install]

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
    create_site
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

        @totals = site_statistics_totals
        @recent_elements = @site.site_elements.active.recent(5)
      end

      format.json { render json: @site }
    end
  end

  def improve
    @totals = site_statistics_totals
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
    render js: render_script(preview: true)
  end

  # Returns the site's script
  def script
    render js: render_script(preview: false)
  end

  def chart_data
    render json: site_statistics_graph, root: false
  end

  def tabs_data
    @totals = site_statistics_totals
    render layout: false
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

  def site_statistics_graph
    return development_data_set if Settings.elastic_search_endpoint == 'http://es.com:9200'

    @site_statistics ||=
      FetchGraphStatisticsFromES.new(@site, params['start_date'], params['end_date'], params[:type]).call
  end

  def site_statistics_totals
    FetchSiteStatistics.new(@site, days_limit: @site.capabilities.num_days_improve_data).call
    return { call: 10.0, total: 120.0, social: 30.0, email: 30.0, traffic: 50.0 } if Settings.elastic_search_endpoint == 'http://es.com:9200'

    FetchSiteStatisticsFromES.new(@site, params['start_date'], params['end_date']).call
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

  def create_site
    CreateSite.new(@site, current_user, cookies: cookies, referral_token: session[:referral_token]).call
    track_event
    redirect_to new_site_site_element_path(@site)
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:error] = e.record.errors.full_messages
    render action: :new
  rescue CreateSite::DuplicateURLError => e
    flash[:error] = e.message
    return redirect_to site_path(e.existing_site)
  end

  def track_event
    TrackEvent.new(:bar_not_created, user: current_user, site: @site).call
    TrackEvent.new(:not_installed_script, user: current_user, site: @site).call
    TrackEvent.new(:ab_test_not_created, user: current_user, site: @site).call
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
    @bills = @site.bills.not_voided.not_pending.non_free.includes(:subscription).reorder(bill_at: :desc)
    @next_bill = @site.bills.pending.where(description: nil).includes(:subscription).last

    @next_overage_bills = (@site.overage_count * 5) unless @site.overage_count == 0
    @current_view_count = @site.number_of_views
  end

  def check_free_overage
    @free_overage = @site.deactivated?
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

  def development_data_set
    @site_statistics ||=
      (((params['start_date'] || 7.days.ago).to_date)..(params['end_date'] || Date.current).to_date).to_a.collect do |date|
        { date: date.strftime('%-m/%d'), value: rand(100) }
      end
  end
end
