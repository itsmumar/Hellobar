describe SendDigestEmailJob do
  let(:job) { described_class }
  let(:site) { create :site }

  describe '#perform' do
    let(:perform) { job.new.perform(site) }

    before do
      expect(FetchSiteStatistics)
        .to receive_service_call
        .with(site, days_limit: 14)
        .and_return(statistics)
    end

    context 'when site has views' do
      let(:statistics) { create :site_statistics, views: [1], first_date: 9.days.ago }

      it 'calls SendEmailDigest' do
        expect(SendEmailDigest).to receive_service_call.with(site)
        perform
      end
    end

    context 'when site has no views' do
      let(:statistics) { create :site_statistics, views: [0], first_date: 9.days.ago }

      it 'does not call SendEmailDigest' do
        expect(SendEmailDigest).not_to receive_service_call.with(site)
        perform
      end
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test_lowpriority'
    end
  end
end
