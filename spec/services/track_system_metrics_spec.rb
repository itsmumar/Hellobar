describe TrackSystemMetrics, :freeze do
  let(:service) { TrackSystemMetrics.new }
  let(:amplitude_event) { instance_double(AmplitudeAPI::Event) }

  let(:active_sites) { 5 }
  let(:active_users) { 6 }
  let(:active_site_elements) { 7 }

  let(:event_properties) do
    {
      active_sites: active_sites,
      active_users: active_users,
      active_site_elements: active_site_elements
    }
  end

  let(:event_attributes) do
    {
      time: Time.current,
      event_type: TrackSystemMetrics::EVENT,
      device_id: TrackSystemMetrics::DEVICE_ID,
      event_properties: event_properties
    }
  end

  before do
    allow(Rails.env).to receive(:production?).and_return true

    allow(AmplitudeAPI::Event)
      .to receive(:new)
      .with(event_attributes)
      .and_return amplitude_event

    allow(Site).to receive_message_chain(:active, :count).and_return(active_sites)
    allow(User).to receive_message_chain(:joins, :merge, :count).and_return(active_users)
    allow(SiteElement).to receive_message_chain(:joins, :merge, :count).and_return(active_site_elements)
  end

  it 'sends `system` event to amplitude' do
    expect(AmplitudeAPI).to receive(:track).with(amplitude_event)

    service.call
  end
end
