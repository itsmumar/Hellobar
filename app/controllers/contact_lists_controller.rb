class ContactListsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site
  before_filter :load_contact_list, :only => [:show]

  def index
    @contact_lists = @site.contact_lists
  end

  def create
    @site.contact_lists.create(contact_list_params)
    redirect_to site_contact_lists_path(@site)
  end

  def show
    @subscribers = @contact_list.subscribers

    respond_to do |format|
      format.html
      format.csv { send_data @contact_list.to_csv }
    end
  end

  private

  def contact_list_params
    params.require(:contact_list).permit(:name)
  end

  def load_site
    @site = current_user.sites.find(params[:site_id])
  end

  def load_contact_list
    @contact_list = @site.contact_lists.find(params[:id])
  end
end
