class TrackEvent
  def initialize(event, **args)
    @event = event
    @args = args
  end

  def call
    track_with_intercom
    track_with_amplitude
    track_with_profitwell
  end

  def trigger
    track_with_amplitude
  end

  private

  attr_reader :event, :args

  def track_with_intercom
    return unless intercom_enabled?
    SendEventToIntercomJob.perform_later event.to_s, args
  end

  def track_with_amplitude
    return unless amplitude_enabled?
    SendEventToAmplitudeJob.perform_later event.to_s, args
  end

  def track_with_profitwell
    return unless profitwell_enabled?

    SendEventToProfitwellJob.perform_later event.to_s, args
  end

  def intercom_enabled?
    Rails.env.edge? || Rails.env.production?
  end

  def amplitude_enabled?
    Rails.env.production?
  end

  def profitwell_enabled?
    Rails.env.production? &&
      event.to_sym.in?([:upgraded_subscription, :downgraded_subscription])
  end
end
