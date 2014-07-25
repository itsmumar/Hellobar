class ContactListsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site

  def index
    @contact_lists = @site.contact_lists
  end

  def create
    @site.contact_lists.create(contact_list_params)
    redirect_to site_contact_lists_path(@site)
  end

  private

  def contact_list_params
    params.require(:contact_list).permit(:name)
  end

  def load_site
    @site = current_user.sites.find(params[:site_id])
  end
end
