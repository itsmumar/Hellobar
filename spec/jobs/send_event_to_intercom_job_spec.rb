describe SendEventToIntercomJob do
  let(:job) { described_class }

  describe '#perform' do
    context 'with "subscription_changed" event' do
      let(:site) { create :site }
      let(:perform) { job.new.perform('subscription_changed', site: site) }

      it 'calls on the IntercomAnalytics' do
        expect_any_instance_of(IntercomAnalytics).to receive(:subscription_changed).with(site: site)
        perform
      end
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later('event')
      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test_lowpriority'
    end
  end
end
