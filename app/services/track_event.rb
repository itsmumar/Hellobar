class TrackEvent
  def initialize(event, **args)
    @event = event
    @args = args
  end

  def call
    SendEventToIntercomJob.perform_later event.to_s, args
    SendEventToDiamondAnalyticsJob.perform_later event.to_s, args
  end

  private

  attr_reader :event, :args
end
