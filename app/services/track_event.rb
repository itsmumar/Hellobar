class TrackEvent
  def initialize(event, **args)
    @event = event
    @args = args
  end

  def call
    return unless Rails.env.production?

    track_with_intercom
    track_with_amplitude
    track_with_profitwell
  end

  private

  attr_reader :event, :args

  def track_with_intercom
    SendEventToIntercomJob.perform_later event.to_s, args
  end

  def track_with_amplitude
    SendEventToAmplitudeJob.perform_later event.to_s, args
  end

  def track_with_profitwell
    case event
    when :upgraded_subscription, :downgraded_subscription
      SendEventToProfitwellJob.perform_later event.to_s, args
    end
  end
end
