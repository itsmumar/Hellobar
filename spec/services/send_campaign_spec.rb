describe SendCampaign do
  describe '#call' do
    it 'calls SendSnsNotification with appropriate message' do
      contact_list = build_stubbed :contact_list
      campaign = build_stubbed :campaign, contact_list: contact_list

      message_hash = {
        body: campaign.body,
        contactListId: contact_list.id,
        campaignId: campaign.id,
        environment: 'test',
        fromEmail: campaign.from_email,
        fromName: campaign.from_name,
        subject: campaign.subject
      }

      expect(SendSnsNotification).to receive_service_call
        .with(
          a_hash_including(
            topic_arn: a_string_matching(/arn:aws:sns:.+_latest/),
            subject: a_string_matching('sendCampaign'),
            message_hash: message_hash
          )
        )

      SendCampaign.new(campaign).call
    end
  end
end
