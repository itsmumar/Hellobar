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
    @contact_list_totals = FetchContactListTotals.new(@site).call
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
      TrackEvent.new(:created_contact_list, contact_list: contact_list, user: current_user).call
      render json: contact_list, status: :created
    else
      render json: contact_list, status: :bad_request
    end
  end

  def show
    respond_to do |format|
      format.html do
        @other_lists = @site.contact_lists.where.not(id: @contact_list.id)
        @subscribers = FetchContacts.new(@contact_list).call
        @total_subscribers = FetchContactListTotals.new(@site, id: params[:id]).call
        @email_statuses = @contact_list.statuses_for_subscribers(@subscribers)
      end
      format.csv  { send_contact_list_csv(@contact_list) }
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

  def send_contact_list_csv(list)
    send_data FetchContactsCSV.new(list).call, type: 'text/csv', filename: "#{ list.name.parameterize }.csv"
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
