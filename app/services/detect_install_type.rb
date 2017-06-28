class DetectInstallType
  TOPIC_ARN = 'arn:aws:sns:us-east-1:199811731772:lambda_detectInstallType'.freeze

  def initialize site
    @site = site
  end

  def call
    sns.publish(
      topic_arn: TOPIC_ARN,
      subject: "#{ Rails.env };#{ site.id };#{ site.url }",
      message: 'Message'
    )
  end

  private

  attr_reader :site

  def sns
    Aws::SNS::Client.new
  end
end
