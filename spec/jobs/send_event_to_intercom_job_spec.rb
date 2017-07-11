describe SendEventToIntercomJob do
  let(:job) { described_class }

  describe '#perform' do
    context 'with "changed_subscription" event' do
      let(:site) { create :site }
      let(:perform) { job.new.perform('changed_subscription', site: site) }

      it 'calls on the IntercomAnalytics' do
        expect_any_instance_of(IntercomAnalytics).to receive(:changed_subscription).with(site: site)
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
