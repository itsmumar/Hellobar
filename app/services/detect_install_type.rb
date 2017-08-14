class DetectInstallType
  def initialize site
    @site = site
  end

  def call
    send_sns_notification
  end

  private

  attr_reader :site

  def send_sns_notification
    SendSnsNotification.new(notification).call
  end

  def notification
    {
      topic_arn: topic_arn,
      subject: subject,
      message_hash: message_hash
    }
  end

  def topic_arn
    Settings.sns['lambda_detect_install_type']
  end

  def subject
    "detectInstallType() for Site#id #{ site.id }"
  end

  def message_hash
    {
      environment: Rails.env,
      siteId: site.id,
      siteUrl: site.url
    }
  end
end
