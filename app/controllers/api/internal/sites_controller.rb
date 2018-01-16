class Api::Internal::SitesController < Api::Internal::ApplicationController
  def update_install_type
    site.update_column :install_type, site_install_type_params[:install_type]

    head :ok
  end

  def update_static_script_installation
    UpdateStaticScriptInstallation.new(
      site,
      installed: site_installed_params[:installed]
    ).call

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
end
