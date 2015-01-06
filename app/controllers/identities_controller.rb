class IdentitiesController < ApplicationController
  before_action :load_site

  def new
    redirect_to "/auth/#{params[:provider]}/?site_id=#{@site.id}&redirect_to=#{request.referrer}"
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

    identity.credentials = env["omniauth.auth"]["credentials"]
    identity.extra = env["omniauth.auth"]["extra"]

    if identity.save
      flash[:success] = "We've successfully connected your #{identity.provider_config[:name]} account."
    else
      flash[:error] = "There was a problem connecting your #{identity.provider_config[:name]} account. Please try again later."
    end

    redirect_to env["omniauth.params"]["redirect_to"]
  end

  private

  def load_site
    @site ||= current_user.sites.find(params[:site_id] || env["omniauth.params"]["site_id"])
  end
end
