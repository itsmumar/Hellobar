class Api::ContactListsController < Api::ApplicationController
  def index
    render json: site.contact_lists,
           each_serializer: ContactListSerializer,
           context: subscriber_totals
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def subscriber_totals
    @subscriber_totals ||= FetchContactListTotals.new(site).call
  end
end
