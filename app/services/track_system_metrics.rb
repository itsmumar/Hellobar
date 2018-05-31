class TrackSystemMetrics
  EVENT = 'system_metrics'.freeze
  DEVICE_ID = 'hello-bar'.freeze

  def call
    return unless Rails.env.production?

    send_event(
      event_type: EVENT,
      device_id: DEVICE_ID,
      event_properties: event_properties
    )
  end

  private

  def event_properties
    {
      active_sites_number: active_sites_number
    }
  end

  def active_sites_number
    Site.active.count
  end

  def send_event(attributes)
    event = AmplitudeAPI::Event.new({ time: Time.current }.merge(attributes))
    AmplitudeAPI.track(event)
  end
end
