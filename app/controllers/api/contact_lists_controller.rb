class Api::ContactListsController < Api::ApplicationController
  def index
    render json: site.contact_lists,
           each_serializer: ContactListSerializer,
           context: subscriber_totals
  end

  private

  def site
    @site ||= Site.find(params[:site_id])
  end

  def subscriber_totals
    @subscriber_totals ||= FetchContactListTotals.new(@current_site).call
  end
end
