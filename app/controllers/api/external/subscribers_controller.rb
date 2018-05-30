class Api::External::SubscribersController < Api::External::ApplicationController
  before_action -> { doorkeeper_authorize! :contact_lists }

  wrap_parameters false

  def index
    subscribers = FetchSubscribers.new(contact_list).call[:items]
    render json: subscribers, each_serializer: ::External::SubscriberSerializer
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def contact_list
    @contact_list ||= site.contact_lists.find(params[:contact_list_id])
  end
end
