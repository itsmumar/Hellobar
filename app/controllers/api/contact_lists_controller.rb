class Api::ContactListsController < Api::ApplicationController
  def index
    render json: @current_site.contact_lists,
      each_serializer: ContactListSerializer,
      context: subscriber_totals
  end

  private

  def subscriber_totals
    @subscriber_totals ||= FetchContactListTotals.new(@current_site).call
  end
end
