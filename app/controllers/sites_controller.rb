class SitesController < ApplicationController
  include SitesHelper

  before_action :authenticate_user!, except: :create
  before_action :load_site, except: %i[index new create]
  before_action :load_top_performers, only: :improve
  before_action :load_bills, only: :edit

  skip_before_action :verify_authenticity_token, only: %i[preview_script script]

  layout :determine_layout

  def new
    @site = Site.new(url: params[:url])

    flash.now[:notice] = "Are you sure you want to add the site #{ @site.url }?" if params[:url]
  end

  def create
    @site = Site.new(site_params)
    cookies.permanent[:registration_url] = params[:site][:url]

    if current_user
      create_for_logged_in_user
    elsif !@site.valid?
      flash[:error] = 'Your URL is not valid. Please double-check it and try again.'
      redirect_to get_started_path
    elsif params[:source] == 'landing' && @site.url_exists?
      redirect_to new_user_session_path(existing_url: @site.url, oauth: params[:oauth])
    elsif params[:oauth]
      session[:new_site_url] = @site.url
      redirect_to '/auth/google_oauth2'
    else
      create_for_temporary_user
    end
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
        @recent_elements = @site.site_elements.recent(5)
      end
      format.json { render json: @site }
    end
  end

  def improve
    @totals = site_statistics
  end

  def update
    if @site.update_attributes(site_params)
      flash[:success] = 'Your settings have been updated.'
      redirect_to site_path(@site)
    else
      load_bills
      flash.now[:error] = @site.errors.full_messages
      render action: :edit
    end
  end

  def destroy
    @site.bills.pending.map(&:voided!)
    @site.destroy
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

  def install_redirect
    redirect_to site_install_path(current_site)
  end

  private

  def site_statistics
    @site_statistics ||=
      FetchSiteStatistics.new(@site, days_limit: @site.capabilities.num_days_improve_data).call
  end

  def site_params
    if session[:new_site_url]
      params[:site] ||= {}
      params[:site][:url] ||= session[:new_site_url]
      session.delete(:new_site_url)
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

  def generate_temporary_logged_in_user
    sign_in(User.generate_temporary_user)
  end

  def create_for_temporary_user
    if @site.save
      generate_temporary_logged_in_user
      Referrals::HandleToken.run(user: current_user, token: session[:referral_token])
      Analytics.track(*current_person_type_and_id, 'Signed Up', ip: request.remote_ip, url: @site.url, site_id: @site.id)

      SiteMembership.create!(site: @site, user: current_user)
      Analytics.track(*current_person_type_and_id, 'Created Site', site_id: @site.id)
      ChangeSubscription.new(@site, subscription: 'free', schedule: 'monthly').call

      @site.create_default_rules

      DetectInstallType.new(@site).call

      redirect_to new_site_site_element_path(@site)
    else
      flash[:error] = 'Your URL is not valid. Please double-check it and try again.'
      redirect_to get_started_path
    end
  end

  def create_for_logged_in_user
    if @site.valid? && @site.url_exists?(current_user)
      flash[:error] = 'Url is already in use.'
      sites = current_user.sites.merge(Site.protocol_ignored_url(@site.url))
      redirect_to site_path(sites.first)
    elsif @site.save
      Referrals::HandleToken.run(user: current_user, token: session[:referral_token])
      SiteMembership.create!(site: @site, user: current_user)
      Analytics.track(*current_person_type_and_id, 'Created Site', site_id: @site.id)
      ChangeSubscription.new(@site, subscription: 'free', schedule: 'monthly').call

      @site.create_default_rules

      DetectInstallType.new(@site).call
      TrackEvent.new(:created_site, site: @site, user: current_user).call
      redirect_to new_site_site_element_path(@site)
    else
      flash.now[:error] = @site.errors.full_messages
      render action: :new
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
    @bills = @site.bills.paid_or_problem.non_free.includes(:subscription).reorder(bill_at: :desc)
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
