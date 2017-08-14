describe Analytics do
  let(:analytics) { described_class }
  let(:file) { double('log file', puts: true) }

  before do
    allow(analytics.log_file).to receive(:open).with(File::WRONLY | File::APPEND).and_yield(file)
  end

  describe '#alias' do
    let(:visitor_id) { 'visitor id' }
    let(:user_id) { 999 }
    let(:data) { [:visitor, visitor_id, :user_id, value: user_id] }
    let(:call_alias) { analytics.alias(visitor_id, user_id) }

    it 'puts data to log/analytics.log', :freeze do
      call_alias
      expect(file).to have_received(:puts).with analytics_record(*data)
    end

    it 'queues Diamond identity call' do
      expect(SendEventToDiamondAnalyticsJob).to receive(:perform_later)
        .with('identify', timestamp: match(Float), identities: { visitor_id: visitor_id, user_id: user_id })

      call_alias
    end
  end

  describe '#track', :freeze do
    let(:data) { [:user, 1, 'Event Name', foo: 1, bar: 2] }
    let(:track) { analytics.track(*data) }

    it 'puts data to log/analytics.log' do
      expect(file).to receive(:puts).with analytics_record(*data)
      track
    end
  end

  def analytics_record(target_type, target_id, event_name, props)
    table_name = "#{ target_type } #{ event_name }".downcase.underscore.tr(' ', '_')
    { table_name => props.merge(at: Time.current.to_s, id: target_id) }.to_json
  end

  def segment_attributes(target_type, target_id, event_name, props)
    case target_type
    when :user
      {
        event: event_name,
        properties: props.merge(at: Time.current.to_s, id: target_id),
        user_id: target_id
      }
    when :visitor
      {
        event: event_name,
        properties: props.merge(at: Time.current.to_s, id: target_id),
        anonymous_id: target_id
      }
    when :site
      {
        event: event_name,
        properties: props.merge(at: Time.current.to_s, id: target_id),
        site_id: target_id,
        anonymous_id: "anonymous site #{ target_id }"
      }
    end
  end
end
