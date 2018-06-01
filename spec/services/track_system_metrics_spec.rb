describe TrackSystemMetrics, :freeze do
  let(:service) { TrackSystemMetrics.new }
  let(:amplitude_event) { instance_double(AmplitudeAPI::Event) }
  let(:event_attributes) do
    {
      time: Time.current,
      event_type: TrackSystemMetrics::EVENT,
      device_id: TrackSystemMetrics::DEVICE_ID,
      event_properties: event_properties
    }
  end

  let(:event_properties) do
    {
      active_sites_number: active_sites_number
    }
  end

  let(:active_sites_number) { 999 }

  before do
    allow(Rails.env).to receive(:production?).and_return true

    allow(AmplitudeAPI::Event)
      .to receive(:new)
      .with(event_attributes)
      .and_return amplitude_event
  end

  it 'sends `system` event to amplitude' do
    allow(Site).to receive_message_chain(:active, :count).and_return(active_sites_number)
    expect(AmplitudeAPI).to receive(:track).with(amplitude_event)
    service.call
  end
end
