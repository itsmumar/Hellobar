class Api::WhitelabelsController < Api::ApplicationController
  def create
    whitelabel = CreateWhitelabel.new(site: site, params: whitelabel_params).call

    render json: whitelabel, status: :created
  end

  def show
    render json: site.whitelabel
  end

  def destroy
    site.whitelabel&.destroy!
    head :ok
  end

  private

  def site
    @site ||= Site.find params[:site_id]
  end

  def whitelabel_params
    params.require(:whitelabel).permit :domain, :subdomain
  end
end
