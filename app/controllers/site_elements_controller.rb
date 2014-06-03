class SiteElementsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site, :only => :index

  layout "with_sidebar"


  private

  def load_site
    @site = current_user.sites.find(params[:site_id])
  end
end
