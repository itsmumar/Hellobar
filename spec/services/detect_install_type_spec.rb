describe DetectInstallType do
  describe '#call' do
    it 'publishes a new AWS SNS notification' do
      site = instance_double Site, id: 1, url: 'http://localhost'
      sns = instance_double Aws::SNS::Client
      message_params = Hash[environment: 'test', siteId: site.id, siteUrl: site.url]
      message = JSON.generate message_params

      expect(Aws::SNS::Client).to receive(:new).and_return sns
      expect(sns).to receive(:publish)
        .with(a_hash_including(message: message))

      DetectInstallType.new(site).call
    end
  end
end
