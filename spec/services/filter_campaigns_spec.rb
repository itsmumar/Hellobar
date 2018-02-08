describe FilterCampaigns do
  let(:site) { create :site }

  let(:new_campaign) { create :campaign, :new, site: site }
  let(:another_new_campaign) { create :campaign, :new, site: site }
  let(:sending_campaign) { create :campaign, :sending, site: site }
  let(:sent_campaign) { create :campaign, :sent, site: site }
  let(:archived_campaign) { create :campaign, :archived, site: site }

  let!(:all_campaigns) do
    [new_campaign, another_new_campaign, sending_campaign, sent_campaign, archived_campaign]
  end

  let(:drafts) do
    [new_campaign, another_new_campaign, sending_campaign]
  end

  let(:sent) do
    [sent_campaign]
  end

  let(:archived) do
    [archived_campaign]
  end

  describe '#call' do
    context 'when filter is :archived' do
      it 'returns a list of archived campaigns with global statistics' do
        filter = :archived
        campaigns, statistics = FilterCampaigns.new(site, filter: filter).call

        expect(campaigns).to match_array archived
        expect(statistics[:total]).to eql all_campaigns.size
        expect(statistics[:drafts]).to eql drafts.size
        expect(statistics[:sent]).to eql sent.size
        expect(statistics[:archived]).to eql archived.size
      end
    end

    context 'when filter is nil' do
      it 'returns a list of sent campaigns' do
        campaigns, statistics = FilterCampaigns.new(site).call

        expect(campaigns).to match_array sent
        expect(statistics[:total]).to eql all_campaigns.size
      end
    end

    context 'when filter is unknown' do
      it 'returns a list of sent campaigns (default)' do
        campaigns, = FilterCampaigns.new(site).call

        expect(campaigns).to match_array sent
      end
    end
  end
end
