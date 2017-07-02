class Admin::ContactListsController < AdminController
  before_action :load_site

  def index
    @contact_lists = @site.contact_lists.includes(:contact_list_logs)
  end

  private

  def load_site
    @site = Site.find(params[:site_id])
  end
end
