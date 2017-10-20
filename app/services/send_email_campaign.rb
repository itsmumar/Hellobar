class SendEmailCampaign
  def initialize email_campaign
    @email_campaign = email_campaign
  end

  def call
    send_sns_notification
  end

  private

  attr_reader :email_campaign

  delegate :contact_list, to: :email_campaign

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
    Settings.sns['lambda_send_email_campaign']
  end

  def notification_subject
    "sendEmailCampaign() for EmailCampaign#id #{ email_campaign.id } and " \
    "ContactList##{ contact_list.id }"
  end

  def message_hash
    {
      body: email_campaign.body,
      contactListId: contact_list.id,
      emailCampaignId: email_campaign.id,
      environment: Rails.env,
      fromEmail: email_campaign.from_email,
      fromName: email_campaign.from_name,
      subject: email_campaign.subject
    }
  end
end
