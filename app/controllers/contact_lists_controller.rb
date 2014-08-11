class ContactListsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site
  before_filter :load_contact_list, :only => [:show, :update]

  def index
    @contact_lists = @site.contact_lists
  end

  def create
    @contact_list = @site.contact_lists.create(contact_list_params)
    render :json => @contact_list
  end

  def show
    @subscribers = @contact_list.subscribers

    respond_to do |format|
      format.html
      format.csv  { send_data @contact_list.to_csv }
      format.json { render :json => @contact_list }
    end
  end

  def update
    @contact_list.update_attributes(contact_list_params)
    render :json => @contact_list
  end

  def inflight
    if session[:inflight_contact_list_params].blank?
      render :json => {}, :status => 404
    else
      render :json => session.delete(:inflight_contact_list_params)
    end
  end

  private

  def contact_list_params
    params.require(:contact_list).permit(:name, :provider, {:data => [:remote_id, :remote_name]})
  end

  def load_site
    @site = current_user.sites.find(params[:site_id])
  end

  def load_contact_list
    @contact_list = @site.contact_lists.find(params[:id])
  end
end
