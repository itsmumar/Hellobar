class Api::External::ContactListsController < Api::External::ApplicationController
  before_action -> { doorkeeper_authorize! :contact_lists }

  wrap_parameters false

  def index
    contact_lists = site.contact_lists.where(identity_id: nil).to_a
    render json: contact_lists.to_a, each_serializer: ::External::ContactListSerializer
  end

  def subscribe
    ContactListSubscribe.new(contact_list, params).call
    render json: contact_list, serializer: ::External::ContactListSerializer
  end

  def unsubscribe
    ContactListUnsubscribe.new(contact_list).call
    render json: contact_list, serializer: ::External::ContactListSerializer
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def contact_list
    @contact_list ||= site.contact_lists.find(params[:id])
  end
end
