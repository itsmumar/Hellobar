describe SendTestEmailForCampaign do
  let(:campaign) { build_stubbed :campaign }
  let(:contacts) { [{ email: 'email@example.com', name: 'Name' }] }
  let(:service) { SendTestEmailForCampaign.new(campaign, contacts) }

  describe '#call' do
    it 'calls SendSnsNotification with appropriate message' do
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

      service.call
    end

    context 'without contacts' do
      let(:contacts) { [{}, nil] }

      it 'does not call SendSnsNotification' do
        expect(SendSnsNotification).not_to receive_service_call
        service.call
      end
    end
  end
end
