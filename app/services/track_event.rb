class TrackEvent
  def initialize(event, **args)
    @event = event
    @args = args
  end

  def call
    track_with_intercom
    track_with_diamond
  end

  private

  attr_reader :event, :args

  def track_with_intercom
    SendEventToIntercomJob.perform_later event.to_s, args
  end

  def track_with_diamond
    SendEventToDiamondAnalyticsJob.perform_later event.to_s, args
  end
end
