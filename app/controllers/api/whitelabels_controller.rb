class Api::WhitelabelsController < Api::ApplicationController
  def create
    whitelabel = Whitelabel.create! whitelabel_params
    render json: whitelabel, status: :created
  end

  def show
    render json: site.whitelabel
  end

  private

  def site
    @site ||= Site.find params[:site_id]
  end

  def whitelabel_params
    params.require(:whitelabel).permit :domain, :subdomain, :site_id
  end
end
