describe SiteDetectorJob do
  let(:job) { described_class }
  let(:site) { create :site }

  describe '#perform' do
    let(:perform) { job.new.perform(site) }

    it 'calls on the DetectSiteType' do
      expect(DetectSiteType).to receive_service_call.with(site.url).and_return('install type')
      expect { perform }.to change { site.reload.install_type }.from(nil).to('install type')
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.main_queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq 'hellobar_test'
    end
  end
end
