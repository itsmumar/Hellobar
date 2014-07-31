class IdentitiesController < ApplicationController
  before_filter :load_site

  def new
    # TODO: store any unpersisted contact list attributes so that they can be picked up after oauth
    # anything sent to the oauth path in query params will be present in the callback in env['omniauth.params']

    redirect_to "/auth/#{params[:provider]}/?site_id=#{@site.id}"
  end

  def create
    binding.pry
    identity = Identity.find_or_initialize_by_site_id_and_provider(@site.id, params[:provider])

    if @site and identity.persisted?
      flash[:error] = "Please disconnect your #{identity.provider_config[:name]} before adding a new one."
      return redirect_to site_settings_path(@site)
    end

    identity.credentials = env['omniauth.auth']['credentials']
    identity.extra = env['omniauth.auth']['extra']

    if identity.save
      flash[:notice] = "We've successfully connected your #{identity.provider_config[:name]} account."
    else
      flash[:error] = "There was a problem connecting your #{identity.provider_config[:name]} account. Please try again later."
    end

    # TODO: how to redirect here?
    redirect_to root_path
  end

  private

  def load_site
    @site = current_user.sites.find(params[:site_id] || env['omniauth.params']['site_id'])
  end
end
