class ContactListsController < ApplicationController
  include OmniauthErrors

  before_action :authenticate_user!
  before_action :load_site
  before_action :load_contact_list, only: %i[show update destroy]

  def index
    @site ||= current_site # Necessary here in case this is a redirect from failed oauth
    flash[:error] = omniauth_error_message if omniauth_error?

    @contact_lists = @site.contact_lists
    @contact_list_totals =
      Hello::DataAPI.contact_list_totals(@site, @contact_lists) || {}
  end

  def create
    identity = @site.identities.find params[:identity_id] if params[:identity_id].present?
    contact_list = @site.contact_lists.create(contact_list_params.merge(identity: identity))
    render json: contact_list, status: contact_list.persisted? ? :created : :bad_request
  end

  def show
    @other_lists = @site.contact_lists.where.not(id: @contact_list.id)
    @subscribers = @contact_list.subscribers(100)
    @total_subscribers = Hello::DataAPI.contact_list_totals(@site, [@contact_list])[@contact_list.id.to_s]
    @sent_contacts = @contact_list.contact_list_logs.processed(@subscribers)

    respond_to do |format|
      format.html
      format.csv  { redirect_to contact_list_csv_url(@contact_list) }
      format.json { render json: @contact_list }
    end
  end

  def update
    result = @contact_list.update_attributes(contact_list_params)
    status = result ? :ok : :bad_request
    render json: @contact_list, status: status
  end

  def destroy
    destroyed = ContactLists::Destroy.run(
      contact_list: @contact_list,
      site_elements_action: delete_site_elements_action
    )

    if destroyed
      render json: { id: @contact_list.id }, status: :ok
    else
      render json: @contact_list, status: :bad_request
    end
  end

  private

  def contact_list_params
    params.require(:contact_list).permit(:name, :provider_token, { data: [:remote_id, :remote_name, :embed_code, :api_key, :app_url, :webhook_url, :webhook_method, :cycle_day, tags: []] }, :double_optin)
  end

  def delete_site_elements_action
    params[:contact_list][:site_elements_action]
  end

  def load_contact_list
    @contact_list = @site.contact_lists.find(params[:id])
  end

  def contact_list_csv_url(list)
    path, params = Hello::DataAPIHelper::RequestParts.contacts(list.site_id, list.id, list.site.read_key, nil, nil, 'f' => 'c')
    path_with_params = Hello::DataAPIHelper.url_for(path, params)
    URI.join(Settings.data_api_url, path_with_params).to_s
  end
end
