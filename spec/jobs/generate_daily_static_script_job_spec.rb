describe GenerateDailyStaticScriptJob do
  let(:job) { described_class }
  let(:site) { create :site }

  describe '#perform' do
    let(:perform) { job.new.perform(site) }
    let(:site) { create :site, script_generated_at: 4.hours.ago }

    it 'calls on the GenerateAndStoreStaticScript' do
      expect(GenerateAndStoreStaticScript).to receive_service_call.with(site)
      perform
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test_lowpriority'
    end
  end
end
