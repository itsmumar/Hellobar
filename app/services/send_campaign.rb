class SendCampaign
  def initialize campaign
    @campaign = campaign
  end

  def call
    return unless send_campaign!

    reload_campaign
    send_sns_notification
  end

  private

  attr_reader :campaign

  delegate :contact_list, to: :campaign

  def send_campaign!
    # Method update_all return the number of updated records. So it guarantees that only single
    # process/thread could update the record in DB and only single notification would be sent.
    Campaign.where(id: campaign.id, sent_at: nil).update_all(sent_at: Time.current, status: Campaign::SENT) > 0
  end

  def reload_campaign
    campaign.reload
  end

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
    Settings.sns['lambda_send_campaign']
  end

  def notification_subject
    "sendCampaign() for Campaign#id #{ campaign.id } and " \
    "ContactList##{ contact_list.id }"
  end

  def message_hash
    {
      body: campaign.body,
      contactListId: contact_list.id,
      campaignId: campaign.id,
      environment: Rails.env,
      fromEmail: campaign.from_email,
      fromName: campaign.from_name,
      subject: campaign.subject
    }
  end
end
