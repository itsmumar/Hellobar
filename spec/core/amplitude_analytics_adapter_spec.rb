describe AmplitudeAnalyticsAdapter do
  let!(:user) { create :user, :with_site }
  let(:amplitude_event) { instance_double(AmplitudeAPI::Event) }
  let(:params) { Hash[foo: 'bar'] }
  let(:user_properties) do
    %i[email primary_domain additional_domains contact_lists total_views
       total_conversions sites_count site_elements_count]
  end

  let(:adapter) { AmplitudeAnalyticsAdapter.new }

  before do
    allow(AmplitudeAPI).to receive(:track)
  end

  describe '#track' do
    it 'calls AmplitudeAPI.track', :freeze do
      event_attributes = {
        time: Time.current,
        event_type: 'event',
        user_id: user.id,
        event_properties: params,
        user_properties: hash_including(*user_properties)
      }

      allow(AmplitudeAPI::Event)
        .to receive(:new)
        .with(event_attributes)
        .and_return amplitude_event

      expect(AmplitudeAPI).to receive(:track).with(amplitude_event)

      adapter.track(
        event: 'event',
        user: user,
        params: params
      )
    end
  end
end
