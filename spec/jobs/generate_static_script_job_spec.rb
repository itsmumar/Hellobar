describe GenerateStaticScriptJob do
  let(:job) { described_class }
  let(:site) { create :site }

  describe '#perform' do
    let!(:service) { stub_service CheckStaticScriptInstallation }
    let(:perform) { job.new.perform(site) }

    before { perform }

    it 'calls on the CheckStaticScriptInstallation' do
      expect(service).to have_received :call
    end

    context 'when script_generated_at is blank' do
      let(:site) { create :site, script_generated_at: nil }
      let!(:service) { stub_service GenerateAndStoreStaticScript }

      it 'does not call on the GenerateAndStoreStaticScript' do
        expect(service).not_to have_received :call
      end
    end

    context 'when script has been generated more than 3 hours ago', :freeze do
      let(:site) { create :site, script_generated_at: 4.hours.ago }
      let!(:service) { stub_service GenerateAndStoreStaticScript }

      it 'calls on the GenerateAndStoreStaticScript' do
        expect(service).to have_received :call
      end
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq Settings.low_priority_queue
    end
  end
end
