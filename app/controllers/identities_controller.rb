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

    if params[:app_url].present?
      identity.extra = {"app_url" => sanitize_app_url(params[:app_url])}
    end

    if params[:username]
      identity.credentials = {"username" => params[:username]}
    end

    if params[:api_key]
      #TODO sanitze me?
      identity.api_key = params[:api_key]
      env["omniauth.params"] ||= {}
      env["omniauth.params"].merge!({"redirect_to" => request.referrer})
    else
      identity.credentials = env["omniauth.auth"]["credentials"]
      identity.extra = env["omniauth.auth"]["extra"]
    end

    if identity.save
      flash[:success] = "We've successfully connected your #{identity.provider_config[:name]} account."
    else
      flash[:error] = "There was a problem connecting your #{identity.provider_config[:name]} account. Please try again later."
    end

    redirect_to env["omniauth.params"]["redirect_to"]
  end

  def destroy
    @identity = @site.identities.find(params[:id])
    @identity.destroy
    render :json => @identity
  end

  private

  def load_site
    @site ||= current_user.sites.find(params[:site_id] || env["omniauth.params"]["site_id"])
  end

  def sanitize_app_url(app_url)
    app_url.gsub("https://", "").gsub("http://", "")
  end
end
