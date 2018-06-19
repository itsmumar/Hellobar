class Api::External::SubscribersController < Api::External::ApplicationController
  before_action -> { doorkeeper_authorize! :contact_lists }

  def index
    render json: fetch_subscribers,
           each_serializer: ::External::SubscriberSerializer,
           scope: { contact_list: contact_list.name }
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def contact_list
    @contact_list ||= site.contact_lists.find(params[:contact_list_id])
  end

  def fetch_subscribers
    FetchSubscribers.new(contact_list).call[:items]
  end
end
