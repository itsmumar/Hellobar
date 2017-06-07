describe GenerateStaticScriptJob do
  let(:job) { described_class }
  let(:site) { create :site }

  describe '#perform' do
    let(:perform) { job.new.perform(site) }

    it 'calls on the GenerateAndStoreStaticScript' do
      expect(GenerateAndStoreStaticScript).to receive_service_call.with(site)
      perform
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.main_queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test'
    end
  end
end