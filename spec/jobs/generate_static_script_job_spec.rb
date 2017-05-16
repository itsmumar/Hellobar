describe GenerateStaticScriptJob do
  let(:job) { described_class }
  let(:site) { create :site }

  describe '#perform' do
    let(:perform) { job.new.perform(site) }

    it 'calls on the CheckStaticScriptInstallation' do
      expect(CheckStaticScriptInstallation).to receive_service_call.with(site)
      perform
    end

    context 'when script_generated_at is blank' do
      let(:site) { create :site, script_generated_at: nil }

      it 'does not call on the GenerateAndStoreStaticScript' do
        expect(GenerateAndStoreStaticScript).not_to receive_service_call
        perform
      end
    end

    context 'when script has been generated more than 3 hours ago', :freeze do
      let(:site) { create :site, script_generated_at: 4.hours.ago }

      it 'calls on the GenerateAndStoreStaticScript' do
        expect(GenerateAndStoreStaticScript).to receive_service_call.with(site)
        perform
      end
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test_low_priority'
    end
  end
end
