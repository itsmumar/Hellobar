class IdentitiesController < ApplicationController
  before_filter :load_site

  def new
    session[:inflight_contact_list_params] = params[:contact_list]
    redirect_to "/auth/#{params[:contact_list][:provider]}/?site_id=#{@site.id}"
  end

  def show
    @identity = @site.identities.where(:provider => params[:id]).first
    render :json => @identity
  end

  def create
    identity = Identity.find_or_initialize_by_site_id_and_provider(@site.id, params[:provider])

    if @site and identity.persisted?
      flash[:error] = "Please disconnect your #{identity.provider_config[:name]} before adding a new one."
      return redirect_to site_contact_lists_path(@site)
    end

    identity.credentials = env["omniauth.auth"]["credentials"]
    identity.extra = env["omniauth.auth"]["extra"]

    if identity.save
      flash[:notice] = "We've successfully connected your #{identity.provider_config[:name]} account."
    else
      flash[:error] = "There was a problem connecting your #{identity.provider_config[:name]} account. Please try again later."
    end

    contact_list_id = session["inflight_contact_list_params"]["id"]

    if contact_list_id.blank?
      redirect_to site_contact_lists_path(@site, :inflight_contact_list => true)
    else
      redirect_to site_contact_list_path(@site, contact_list_id, :inflight_contact_list => true)
    end
  end

  private

  def load_site
    @site = current_user.sites.find(params[:site_id] || env["omniauth.params"]["site_id"])
  end
end
