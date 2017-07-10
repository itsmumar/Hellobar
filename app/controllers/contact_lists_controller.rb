class ContactListsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site
  before_action :load_contact_list, only: %i[show update destroy]

  def index
    @site ||= current_site # Necessary here in case this is a redirect from failed oauth

    if omniauth_error?
      flash.now[:error] = omniauth_error_message
      Rails.logger.warn "[Omniauth] [Error] #{ omniauth_error_message }"
    end

    @contact_lists = @site.contact_lists
    @contact_list_totals =
      Hello::DataAPI.contact_list_totals(@site, @contact_lists) || {}
  end

  def create
    provider_token = contact_list_params[:provider_token]

    identity =
      if params[:identity_id].present?
        @site.identities.find params[:identity_id]
      elsif ServiceProvider.embed_code?(provider_token) || provider_token == 'webhooks'
        @site.identities.find_or_create_by(provider: provider_token)
      end

    contact_list = @site.contact_lists.create(contact_list_params.merge(identity: identity))
    if contact_list.persisted?
      TrackEvent.new(:created_bar, contact_list: contact_list, user: current_user).call
      render json: contact_list, status: :created
    else
      render json: contact_list, status: :bad_request
    end
  end

  def show
    @other_lists = @site.contact_lists.where.not(id: @contact_list.id)
    @subscribers = @contact_list.subscribers(100)
    @total_subscribers = Hello::DataAPI.contact_list_totals(@site, [@contact_list])[@contact_list.id.to_s]
    @email_statuses = @contact_list.statuses_for_subscribers(@subscribers)

    respond_to do |format|
      format.html
      format.csv  { redirect_to contact_list_csv_url(@contact_list) }
      format.json { render json: @contact_list }
    end
  end

  def update
    identity = @site.identities.find params[:identity_id] if params[:identity_id].present?
    result = UpdateContactList.new(@contact_list, contact_list_params.merge(identity: identity)).call
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
    data_params = [:remote_id, :remote_name, :embed_code, :api_key, :app_url, :webhook_url, :webhook_method, :cycle_day, tags: []]
    params.require(:contact_list).permit(:name, :provider_token, { data: data_params }, :double_optin)
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

  def omniauth_error?
    request.env['omniauth.error'] || request.env['omniauth.error.type']
  end

  def omniauth_error_message
    message = request.env['omniauth.error'].try(:message) || request.env['omniauth.error.type']
    return nil if message.nil?
    message.to_s.split('|').last.try(:strip) || ''
  end
end
