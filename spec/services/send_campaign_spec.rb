describe SendCampaign do
  subject(:service) { SendCampaign.new(campaign) }

  let(:contact_list) { create(:contact_list) }
  let(:campaign) { create(:campaign, contact_list: contact_list) }

  describe '#call' do
    it 'calls SendSnsNotification with appropriate message' do
      expect(SendSnsNotification).to receive_service_call
        .with(
          a_hash_including(
            topic_arn: a_string_matching(/arn:aws:sns:.+_latest/),
            subject: a_string_matching('sendCampaign'),
            message_hash: a_hash_including(fromName: campaign.email.from_name)
          )
        )

      service.call
    end

    it 'updates campaign\'s status' do
      service.call
      expect(campaign.status).to eq(Campaign::SENDING)
    end

    context 'when campaign has been already sent' do
      before do
        campaign.update(status: Campaign::SENDING)
      end

      it 'does not call SendSnsNotification' do
        expect(SendSnsNotification).not_to receive_service_call
        service.call
      end
    end
  end
end
