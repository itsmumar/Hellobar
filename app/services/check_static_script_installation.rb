class CheckStaticScriptInstallation
  # @param [Site] site
  def initialize(site)
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
    Settings.sns['lambda_install_check']
  end

  def subject
    "installCheck() for Site#id #{ site.id }"
  end

  def message_hash
    {
      environment: Rails.env,
      scriptName: site.script_name,
      siteElementIds: site_element_ids,
      siteId: site.id,
      siteUrl: site.url
    }
  end

  def site_element_ids
    site.site_elements.pluck :id
  end
end
