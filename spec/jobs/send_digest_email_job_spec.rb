describe SendDigestEmailJob do
  let(:job) { described_class }
  let(:site) { create :site }

  describe '#perform' do
    let(:perform) { job.new.perform(site) }

    it 'calls on the SendEmailDigest' do
      expect(SendEmailDigest).to receive_service_call.with(site)
      perform
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq Settings.low_priority_queue
    end
  end
end
