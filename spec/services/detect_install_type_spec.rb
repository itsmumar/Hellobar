describe DetectInstallType do
  describe '#call' do
    it 'calls SendSnsNotification with appropriate message' do
      site = instance_double Site, id: 1, url: 'http://localhost'
      message_hash = Hash[environment: 'test', siteId: site.id, siteUrl: site.url]

      expect(SendSnsNotification).to receive_service_call
        .with(
          a_hash_including(
            topic_arn: a_string_matching(/arn:aws:sns:.+_latest/),
            subject: a_string_matching('detectInstallType'),
            message_hash: message_hash
          )
        )

      DetectInstallType.new(site).call
    end
  end
end
