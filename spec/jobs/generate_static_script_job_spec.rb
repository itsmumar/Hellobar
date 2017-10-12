describe GenerateStaticScriptJob do
  let(:job) { described_class }
  let(:site) { create :site }

  describe '#perform' do
    let(:perform) { job.new.perform(site) }

    it 'calls on the GenerateAndStoreStaticScript' do
      expect(GenerateAndStoreStaticScript).to receive_service_call.with(site)
      perform
    end

    it 'fails gracefully if site has been deleted' do
      site.destroy

      expect(GenerateAndStoreStaticScript).not_to receive_service_call

      perform
    end
  end

  describe '.perform_later' do
    it 'adds the job to the Settings.main_queue queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test'
    end
  end
end
