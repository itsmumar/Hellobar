describe SendTestEmailForCampaign do
  describe '#call' do
    it 'calls SendSnsNotification with appropriate message' do
      campaign = build_stubbed :campaign
      contacts = [{ email: 'email@example.com', name: 'Name' }]

      message_hash = {
        body: campaign.body,
        contacts: contacts,
        environment: 'test',
        fromEmail: campaign.from_email,
        fromName: campaign.from_name,
        subject: campaign.subject
      }

      expect(SendSnsNotification).to receive_service_call
        .with(
          a_hash_including(
            topic_arn: a_string_matching(/arn:aws:sns:.+_latest/),
            subject: a_string_matching('sendEmail'),
            message_hash: message_hash
          )
        )

      SendTestEmailForCampaign.new(campaign, contacts).call
    end
  end
end
