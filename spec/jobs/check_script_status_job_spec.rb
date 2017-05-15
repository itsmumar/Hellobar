describe CheckScriptStatusJob do
  let(:job) { described_class }
  let(:site) { create :site }

  describe '#perform' do
    let!(:service) { stub_service CheckStaticScriptInstallation }
    let(:perform) { job.new.perform(site) }

    before { perform }

    it 'calls on the CheckStaticScriptInstallation' do
      expect(service).to have_received :call
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq Settings.low_priority_queue
    end
  end
end
