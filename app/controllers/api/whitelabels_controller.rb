class Api::WhitelabelsController < Api::ApplicationController
  def show
    render json: site.whitelabel
  end

  private

  def site
    @site ||= Site.find params[:site_id]
  end
end
