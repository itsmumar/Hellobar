class Api::External::ContactListsController < Api::External::ApplicationController
  before_action -> { doorkeeper_authorize! :contact_lists }

  wrap_parameters false

  def index
    contact_lists = site.contact_lists.where(identity_id: nil).to_a
    render json: contact_lists.to_a, each_serializer: ::External::ContactListSerializer
  end

  def subscribe
    UpdateContactList.new(contact_list, subscribe_params).call
    render json: contact_list, serializer: ::External::ContactListSerializer
  end

  def unsubscribe
    UpdateContactList.new(contact_list, unsubscribe_params).call
    render json: contact_list, serializer: ::External::ContactListSerializer
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def contact_list
    @contact_list ||= site.contact_lists.find(params[:id])
  end

  def subscribe_params
    {
      provider_token: params[:provider],
      data: {
        webhook_url: params[:webhook_url],
        webhook_method: params[:webhook_method]
      }
    }
  end

  def unsubscribe_params
    {
      identity: nil
    }
  end
end
