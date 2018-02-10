class Api::SubscribersController < Api::ApplicationController
  def index
    render json: FetchLatestContacts.new(contact_list).call
  end

  def create
    subscriber = CreateSubscriber.new(contact_list, subscriber_params).call
    render json: subscriber
  end

  def update
    subscriber = UpdateSubscriber.new(contact_list, params[:email], subscriber_params).call
    render json: subscriber
  end

  def destroy
    DeleteSubscriber.new(contact_list, params[:email]).call
    render json: FetchLatestContacts.new(contact_list).call
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def contact_list
    @contact_list ||= site.contact_lists.find(params[:contact_list_id])
  end

  def subscriber_params
    params
      .require(:subscriber)
      .permit :contact_list_id, :name, :email
  end
end
