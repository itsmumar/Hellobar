class IdentitiesController < ApplicationController
  before_action :load_site

  def new
    if params[:api_key].blank?
      redirect_to "/auth/#{params[:provider]}/?site_id=#{@site.id}&redirect_to=#{request.referrer}"
    else
      create
    end
  end

  def show
    @identity = @site.identities.where(:provider => params[:id]).first
    # If service provider is not valid, dont render the identity
    @identity = nil if @identity && @identity.service_provider.nil?
    render :json => @identity
  end

  def create
    identity = Identity.where(site_id: @site.id, provider: params[:provider]).first_or_initialize

    if @site && identity.persisted?
      flash[:error] = "Please disconnect your #{identity.provider_config[:name]} before adding a new one."
      return redirect_to site_contact_lists_path(@site)
    end

    identity.extra       = extra_from_request
    identity.credentials = credentials_from_request

    add_account_details(identity)

    if params[:api_key]
      #TODO sanitze me?
      identity.api_key = params[:api_key]
      env['omniauth.params'] ||= {}
      env['omniauth.params'].merge!({ 'redirect_to' => request.referrer })
    end

    if identity.save
      flash[:success] = "We've successfully connected your #{identity.provider_config[:name]} account."
    else
      flash[:error] = "There was a problem connecting your #{identity.provider_config[:name]} account. Please try again later."
    end

    redirect_to after_auth_redirect_url
  end

  def destroy
    @identity = @site.identities.find(params[:id])
    @identity.destroy
    render :json => @identity
  end

  private

  def credentials_from_request
    if params[:api_key] && params[:username].present?
      { 'username' => params[:username] }
    else
      env['omniauth.auth'] && env['omniauth.auth']['credentials']
    end
  end

  def extra_from_request
    if params[:app_url].present?
      { 'app_url' => sanitize_app_url(params[:app_url]) }
    else
      env['omniauth.auth'] && env['omniauth.auth']['extra']
    end
  end

  def add_account_details(identity)
    if identity.provider == 'drip'
      service_provider = identity.service_provider
      account = service_provider.accounts.first
      identity.extra['account_id'] = account.id
      identity.extra['account_name'] = account.name
    end
  end

  def load_site
    @site ||= current_user.sites.find(params[:site_id] || env['omniauth.params']['site_id'])
  end

  def sanitize_app_url(app_url)
    app_url.gsub('https://', '').gsub('http://', '')
  end

  def after_auth_redirect_url
    url = env['omniauth.params']['redirect_to']
    url += '#/settings/emails' if url.include?('/site_elements/')
    url
  end
end
