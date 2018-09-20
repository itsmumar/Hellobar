class SendEventToProfitwellJob < ApplicationJob
  def perform(event, options = {})
    provider.track event: event, **options
  end

  private

  def provider
    ProfitwellAnalyticsAdapter.new
  end
end
