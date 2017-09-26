class IdentitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site

  def new
    if params[:api_key].blank?
      redirect_to "/auth/#{ params[:provider] }/?site_id=#{ @site.id }&redirect_to=#{ request.referrer }"
    else
      create
    end
  end

  def show
    identity = @site.identities.find_by(provider: params[:id])
    identity ||= Identity.from_session(session)

    return render json: nil unless identity

    if identity.service_provider.connected?
      render json: identity
    else
      render json: { error: true, lists: [] }
    end
  end

  def store
    identity = Identity.store_to_session(session, env['omniauth.auth'])

    unless identity.valid?
      flash[:error] = "There was a problem connecting your #{ t(identity.provider, scope: :service_providers) } account. Please verify that you have provided valid credentials and try again."
    end

    redirect_to after_auth_redirect_url
  end

  def create
    identity = Identity.where(site_id: @site.id, provider: params[:provider]).first_or_initialize

    if @site && identity.persisted?
      flash[:error] = "Please disconnect your #{ t(identity.provider, scope: :service_providers) } account first before adding a new one."
      return redirect_to site_contact_lists_path(@site)
    end

    identity.extra       = extra_from_request
    identity.credentials = credentials_from_request
    identity.api_key     = params[:api_key] if params[:api_key]

    if identity.save
      flash[:success] = "We've successfully connected your #{ t(identity.provider, scope: :service_providers) } account."
    else
      flash[:error] = "There was a problem connecting your #{ t(identity.provider, scope: :service_providers) } account. Please verify that you have provided valid credentials and try again."
    end

    redirect_to after_auth_redirect_url
  end

  def destroy
    identity = @site.identities.find(params[:id])

    if identity.destroy
      render json: identity
    else
      head :unprocessable_entity
    end
  end

  private

  def credentials_from_request
    { 'username' => params[:username] } if params[:api_key] && params[:username].present?
  end

  def extra_from_request
    { 'app_url' => sanitize_app_url(params[:app_url]) } if params[:app_url].present?
  end

  def load_site
    @site ||= current_user.sites.find(params[:site_id] || env['omniauth.params']['site_id'])
  end

  def sanitize_app_url(app_url)
    app_url.gsub('https://', '').gsub('http://', '')
  end

  def after_auth_redirect_url
    url = env['omniauth.params']['redirect_to']
    url += '#/goals' if url.include?('/site_elements/')
    url
  end
end
