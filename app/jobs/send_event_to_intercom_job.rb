class SendEventToIntercomJob < ApplicationJob
  def perform(event, options = {})
    IntercomAnalytics.new.fire_event event, options
  end
end
