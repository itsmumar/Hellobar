class SendEventToDiamondJob < ApplicationJob
  def perform(event, options = {})
    DiamondAnalytics.new.fire_event(event, options)
  end
end
