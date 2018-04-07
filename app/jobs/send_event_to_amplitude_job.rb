class SendEventToAmplitudeJob < ApplicationJob
  def perform(event, options = {})
    provider.fire_event event, options
  end

  private

  def provider
    AnalyticsProvider.new(AmplitudeAnalyticsAdapter.new)
  end
end
