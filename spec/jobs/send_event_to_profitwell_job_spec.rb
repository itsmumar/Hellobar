describe SendEventToProfitwellJob do
  let(:job) { described_class }

  describe '#perform' do
    let(:event) { 'foo_bar_event' }
    let(:params) { Hash[subscription: 'subscription', previous_subscription: 'previous_subscription', user: 'user'] }
    let(:analytics) { instance_double ProfitwellAnalyticsAdapter }
    let(:perform) { job.perform_now(event, params) }

    before do
      allow(ProfitwellAnalyticsAdapter)
        .to receive(:new)
        .and_return analytics
    end

    it 'calls ProfitwellAnalyticsAdapter#track' do
      expect(analytics)
        .to receive(:track)
        .with(event: event, **params)

      perform
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later('event')

      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test_lowpriority'
    end
  end
end
