describe DetectInstallType do
  describe '#call' do
    it 'publishes new AWS SNS notification' do
      site = instance_double Site, id: 1, url: 'http://localhost'
      sns = instance_double Aws::SNS::Client
      message = "test;#{ site.id };#{ site.url }"

      expect(Aws::SNS::Client).to receive(:new).and_return sns
      expect(sns).to receive(:publish)
        .with(a_hash_including(message: message))

      DetectInstallType.new(site).call
    end
  end
end
