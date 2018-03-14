class SendTestEmailForCampaign
  def initialize campaign, contacts
    @campaign = campaign
    @contacts = contacts.select(&:present?)
  end

  def call
    return if contacts.blank?
    send_sns_notification
  end

  private

  attr_reader :campaign, :contacts

  def send_sns_notification
    SendSnsNotification.new(notification).call
  end

  def notification
    {
      topic_arn: topic_arn,
      subject: notification_subject,
      message_hash: message_hash
    }
  end

  def topic_arn
    Settings.sns['lambda_send_email']
  end

  def notification_subject
    "sendEmail() to #{ contacts.size } email(s) for Campaign#id #{ campaign.id }"
  end

  def message_hash
    {
      body: campaign.email.body,
      contacts: contacts,
      environment: Rails.env,
      fromEmail: campaign.email.from_email,
      fromName: campaign.email.from_name,
      subject: campaign.email.subject
    }
  end
end
