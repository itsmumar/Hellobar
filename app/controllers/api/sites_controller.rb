class Api::SitesController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :authenticate

  respond_to :json

  def update_install_type
    site.update_column :install_type, site_install_type_params[:install_type]

    head :ok
  end

  def update_static_script_installation
    UpdateStaticScriptInstallation.new(site, installed: site_installed_params[:installed]).call

    head :ok
  end

  private

  def site_installed_params
    params.require(:site).permit :installed
  end

  def site_install_type_params
    params.require(:site).permit :install_type
  end

  def site
    @site ||= Site.find params[:id]
  end

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      token == Settings.api_token
    end
  end
end
