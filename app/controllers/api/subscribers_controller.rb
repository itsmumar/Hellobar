class Api::SubscribersController < Api::ApplicationController
  def index
    render json: fetch_subscribers
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
    render json: fetch_subscribers
  end

  def upload
    if params[:csv].size < 5.kilobytes
      ImportSubscribersFromCsv.new(params[:csv], contact_list).call
      render json: { message: 'Subscribers has been uploaded successfully.' }
    else
      ImportSubscribersFromCsvAsync.new(params[:csv], contact_list).call
      render json: { message: 'We need some time to import all of your subscribers. Please come back later' }
    end
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def contact_list
    @contact_list ||= site.contact_lists.find(params[:contact_list_id])
  end

  def pagination_params
    {
      key: params[:key],
      forward: ActiveRecord::Type::Boolean.new.type_cast_from_user(params[:forward]) || false
    }
  end

  def fetch_subscribers
    FetchSubscribers.new(contact_list, pagination_params).call
  end

  def subscriber_params
    params
      .require(:subscriber)
      .permit :contact_list_id, :name, :email
  end
end
