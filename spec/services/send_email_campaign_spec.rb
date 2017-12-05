describe SendEmailCampaign do
  describe '#call' do
    it 'calls SendSnsNotification with appropriate message' do
      contact_list = build_stubbed :contact_list
      email_campaign = build_stubbed :email_campaign, contact_list: contact_list

      message_hash = {
        body: email_campaign.body,
        contactListId: contact_list.id,
        campaignId: email_campaign.id,
        environment: 'test',
        fromEmail: email_campaign.from_email,
        fromName: email_campaign.from_name,
        subject: email_campaign.subject
      }

      expect(SendSnsNotification).to receive_service_call
        .with(
          a_hash_including(
            topic_arn: a_string_matching(/arn:aws:sns:.+_latest/),
            subject: a_string_matching('sendEmailCampaign'),
            message_hash: message_hash
          )
        )

      SendEmailCampaign.new(email_campaign).call
    end
  end
end
