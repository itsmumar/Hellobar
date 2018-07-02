class SendEventToIntercomJob < ApplicationJob
  def perform(event, options = {})
    provider.fire_event event, options
  rescue Intercom::ResourceNotFound => e
    raise e unless e.message == IntercomAnalyticsAdapter::USER_NOT_FOUND

    handle_user_not_found(options[:user])
    # retry it 1st time without exception
    provider.fire_event event, options
  end

  private

  # if user is not found we have to create him
  # it is possible in case of :created_site event for example
  # cause if user just signed up the intercom script isn't loaded yet
  # it will be loaded on "create new bar" page, just after that event
  # also user's info will be update there
  def handle_user_not_found(user)
    return unless user
    IntercomGateway.new.create_user user
  end

  def provider
    AnalyticsProvider.new(IntercomAnalyticsAdapter.new)
  end
end
