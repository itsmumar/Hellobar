class SendSnsNotification
  def initialize topic_arn:, subject:, message_hash:
    @topic_arn = topic_arn
    @subject = subject
    @message_hash = message_hash
  end

  def call
    sns.publish(
      topic_arn: topic_arn,
      subject: subject,
      message: message
    )
  end

  private

  attr_reader :topic_arn, :subject, :message_hash

  def message
    JSON.generate message_hash
  end

  def sns
    Aws::SNS::Client.new
  end
end
