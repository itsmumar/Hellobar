class DetectInstallTypeJob < ApplicationJob
  TOPIC_ARN = 'arn:aws:sns:us-east-1:199811731772:lambda_detectInstallType'.freeze

  def perform site_id, site_url
    sns.publish(
      topic_arn: TOPIC_ARN,
      subject: "#{ Rails.env };#{ site_id };#{ site_url }",
      message: 'Message'
    )
  end

  private

  def sns
    Aws::SNS::Client.new
  end
end
