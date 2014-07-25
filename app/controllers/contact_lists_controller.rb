class ContactListsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site

  def index
    @contact_lists = @site.contact_lists
  end

  private

  def load_site
    @site = current_user.sites.find(params[:site_id])
  end
end
