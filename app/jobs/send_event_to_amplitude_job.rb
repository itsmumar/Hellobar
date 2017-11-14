class SendEventToAmplitudeJob < ApplicationJob
  def perform(event, options = {})
    AmplitudeAnalytics.new.fire_event event, options
  end
end
