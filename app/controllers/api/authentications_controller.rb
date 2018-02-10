class Api::AuthenticationsController < ApplicationController
  # GET action; user in the Vue.js app will be redirected here to authenticate
  def create
    if current_user && current_site
      redirect_to redirect_url
    else
      redirect_to root_path
    end
  end

  private

  def redirect_url
    "#{ params[:callback_url] }?token=#{ token }&site_id=#{ current_site.id }"
  end

  def token
    JsonWebToken.encode(user_id: current_user.id)
  end
end
