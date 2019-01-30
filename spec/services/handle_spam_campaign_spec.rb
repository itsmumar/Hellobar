describe HandleSpamCampaign do
  let(:campaign) { create :campaign }

  let(:statistics_with_spam_values) do
    {
      'opened' => BigDecimal(1),
      'rejected' => BigDecimal(0),
      'recipients' => BigDecimal(10),
      'reported' => BigDecimal(6),
      'bounced' => BigDecimal(9),
      'delivered' => BigDecimal(4),
      'submitted' => BigDecimal(10),
      'unsubscribed' => BigDecimal(9),
      'id' => BigDecimal(campaign.id),
      'type' => 'campaign'
    }
  end

  let(:statistics_with_non_spam_values) do
    {
      'opened' => BigDecimal(1),
      'rejected' => BigDecimal(0),
      'recipients' => BigDecimal(10),
      'reported' => BigDecimal(2),
      'bounced' => BigDecimal(1),
      'delivered' => BigDecimal(7),
      'submitted' => BigDecimal(10),
      'unsubscribed' => BigDecimal(1),
      'id' => BigDecimal(campaign.id),
      'type' => 'campaign'
    }
  end

  context 'campaign has been sent with spamming statistics' do
    before do
      allow(FetchEmailStatistics).to receive_message_chain(:new, :call)
        .and_return(statistics_with_spam_values)
    end

    it 'set spam column to true' do
      HandleSpamCampaign.new(campaign).call
      expect(campaign.spam).to eq true
    end

    it 'set processed column to true' do
      HandleSpamCampaign.new(campaign).call
      expect(campaign.processed).to eq true
    end
  end

  context 'campaign has been sent with non spamming statistics' do
    before do
      allow(FetchEmailStatistics).to receive_message_chain(:new, :call)
        .and_return(statistics_with_non_spam_values)
    end

    it 'keeps the spam value as false' do
      HandleSpamCampaign.new(campaign).call
      expect(campaign.spam).to eq false
    end

    it 'set processed column to true' do
      HandleSpamCampaign.new(campaign).call
      expect(campaign.processed).to eq true
    end
  end
end
