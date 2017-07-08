class SendEventToIntercomJob < ApplicationJob
  def perform(event, options = {})
    IntercomAnalytics.event event.to_sym, options
  end
end
