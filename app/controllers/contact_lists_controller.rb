class ContactListsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site
  before_action :load_contact_list, :only => [:show, :update]

  def index
    @contact_lists = @site.contact_lists
    @contact_list_totals = Hello::DataAPI.contact_list_totals(@site, @contact_lists) || {}
  end

  def create
    @contact_list = @site.contact_lists.create(contact_list_params)
    render :json => @contact_list, :status => @contact_list.persisted? ? :created : :bad_request
  end

  def show
    @other_lists = @site.contact_lists.where.not(:id => @contact_list.id)
    @subscribers = @contact_list.subscribers(100)
    @total_subscribers = Hello::DataAPI.contact_list_totals(@site, [@contact_list])[@contact_list.id.to_s]
    @statuses = @contact_list.subscriber_statuses(@subscribers)

    respond_to do |format|
      format.html
      format.csv  { redirect_to contact_list_csv_url(@contact_list) }
      format.json { render :json => @contact_list }
    end
  end

  def update
    status = @contact_list.update_attributes(contact_list_params)
    render :json => @contact_list, :status => status ? :ok : :bad_request
  end

  private

  def contact_list_params
    params.require(:contact_list).permit(:name, :provider, {:data => [:remote_id, :remote_name, :embed_code]}, :double_optin)
  end

  def load_contact_list
    @contact_list = @site.contact_lists.find(params[:id])
  end

  def contact_list_csv_url(list)
    path, params = Hello::DataAPIHelper::RequestParts.get_contacts(list.site_id, list.id, list.site.read_key, nil, nil, {"f" => "c"})
    path_with_params = Hello::DataAPIHelper.url_for(path, params)
    URI.join(Hellobar::Settings[:data_api_url], path_with_params).to_s
  end
end
