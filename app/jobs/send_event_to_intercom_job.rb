class SendEventToIntercomJob < ApplicationJob
  rescue_from Intercom::ResourceNotFound do |exception|
    if exception.message == 'User Not Found'
      handle_user_not_found(*arguments)
    else
      Raven.capture_exception exception
    end
  end

  def perform(event, options = {})
    IntercomAnalytics.new.fire_event event, options
  end

  private

  def handle_user_not_found(_event, options)
    return unless options[:user]
    IntercomAnalytics.new.created_user user: options[:user]
    retry_job
  end
end
