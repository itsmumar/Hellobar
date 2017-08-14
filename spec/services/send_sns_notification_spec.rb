describe SendSnsNotification do
  describe '#call' do
    it 'publishes a new AWS SNS notification' do
      sns = instance_double Aws::SNS::Client
      topic_arn = 'arn:aws'
      subject = 'subject'
      message_hash = Hash[environment: 'test']
      message = JSON.generate message_hash

      notification = {
        topic_arn: topic_arn,
        subject: subject,
        message_hash: message_hash
      }

      expect(Aws::SNS::Client).to receive(:new).and_return sns
      expect(sns).to receive(:publish)
        .with(
          a_hash_including(
            topic_arn: topic_arn,
            subject: subject,
            message: message
          )
        )

      SendSnsNotification.new(notification).call
    end
  end
end
