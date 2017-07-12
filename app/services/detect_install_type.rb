class DetectInstallType
  TOPIC_ARN = 'arn:aws:sns:us-east-1:199811731772:lambda_detectInstallType'.freeze

  def initialize site
    @site = site
  end

  def call
    # TODO: change `subject` and introduce SendSNSNotification service object
    # (when new Lambda function parsing the message is deployed)
    sns.publish(
      topic_arn: TOPIC_ARN,
      subject: "detectInstallType() for Site#id #{ site.id }",
      message: message
    )
  end

  private

  attr_reader :site

  def sns
    Aws::SNS::Client.new
  end

  def message
    JSON.generate message_params
  end

  def message_params
    {
      environment: Rails.env,
      siteId: site.id,
      siteUrl: site.url
    }
  end
end
