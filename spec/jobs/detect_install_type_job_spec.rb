describe DetectInstallTypeJob do
  let(:site) { instance_double Site, id: 1, url: 'http://localhost' }

  describe '#perform' do
    it 'publishes new AWS SNS notification' do
      sns = instance_double Aws::SNS::Client
      message = "test;#{ site.id };#{ site.url }"

      expect(Aws::SNS::Client).to receive(:new).and_return sns
      expect(sns).to receive(:publish)
        .with(a_hash_including(subject: message))

      DetectInstallTypeJob.new.perform site.id, site.url
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.main_queue' do
      DetectInstallTypeJob.perform_later site.id, site.url

      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test_lowpriority'
    end
  end
end
