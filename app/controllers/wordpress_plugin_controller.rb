class WordpressPluginController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site

  layout false

  def show
    plugin = WordpressPlugin.new(@site)
    send_data(plugin.to_zip, :type => Mime::ZIP, :filename => "hellobar_wp_plugin.zip")
  ensure
    plugin.cleanup
  end


  private

  def load_site
    @site = current_user.sites.find(params[:site_id])
  end
end
