class SendEventToIntercomJob < ApplicationJob
  def perform(event, options = {})
    IntercomAnalytics.new.fire_event event.to_sym, options
  end
end
