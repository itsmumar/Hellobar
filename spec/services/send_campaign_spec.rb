describe SendCampaign do
  subject(:service) { SendCampaign.new(campaign) }

  let(:contact_list) { create(:contact_list) }
  let(:campaign) { create(:campaign, contact_list: contact_list) }

  describe '#call' do
    it 'calls SendSnsNotification with appropriate message' do
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

      service.call
    end

    it 'updates campaign\'s status' do
      service.call
      expect(campaign.status).to eq(Campaign::SENT)
    end

    it 'updates campaign\'s sent_at' do
      service.call
      expect(campaign.sent_at).to be_present
    end

    context 'when campaign has been already sent' do
      before do
        campaign.update(sent_at: 1.day.ago)
      end

      it 'does not call SendSnsNotification' do
        expect(SendSnsNotification).not_to receive_service_call
        service.call
      end

      it 'does not update campaign\'s sent_at' do
        expect { service.call }.not_to change { campaign.reload.sent_at }
      end
    end
  end
end
