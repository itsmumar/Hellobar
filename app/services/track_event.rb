class TrackEvent
  def initialize(event, **args)
    @event = event
    @args = args
  end

  def call
    return unless Rails.env.production?

    track_with_intercom
    track_with_amplitude
  end

  private

  attr_reader :event, :args

  def track_with_intercom
    SendEventToIntercomJob.perform_later event.to_s, args
  end

  def track_with_amplitude
    SendEventToAmplitudeJob.perform_later event.to_s, args
  end
end
