class SendEventToIntercomJob < ApplicationJob
  def perform(event, options = {})
    IntercomAnalytics.new.fire_event event, options
  rescue Intercom::ResourceNotFound => e
    handle_user_not_found(options[:user]) if e.message == 'User Not Found'
    raise e # let SQS do its job
  end

  private

  # if user is not found we have to create him
  # it is possible in case of :created_site event for example
  # cause if user just signed up the intercom script isn't loaded yet
  # it will be loaded on "create new bar" page, just after that event
  # also user's info will be update there
  def handle_user_not_found(user)
    return unless user
    IntercomAnalytics.new.created_user user: user
  end
end
