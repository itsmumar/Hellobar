describe FilterCampaigns do
  subject(:service) { FilterCampaigns.new(filter: filter) }

  let!(:campaign1) { create(:campaign, status: Campaign::NEW) }
  let!(:campaign2) { create(:campaign, status: Campaign::NEW) }
  let!(:campaign3) { create(:campaign, status: Campaign::SENDING) }
  let!(:campaign4) { create(:campaign, status: Campaign::SENT) }
  let!(:campaign5) { create(:campaign, status: Campaign::ARCHIVED) }

  let(:all_campaigns) do
    [campaign1, campaign2, campaign3, campaign4, campaign5]
  end

  let(:draft_campaigns) do
    [campaign1, campaign2, campaign3]
  end

  let(:archived_campaigns) do
    [campaign5]
  end

  describe '#call' do
    context 'when filter is given' do
      let(:filter) { :archived }

      let(:expected_filters) do
        [
          { key: :draft, title: 'Draft', active: false, count: 3 },
          { key: :sent, title: 'Sent', active: false, count: 1 },
          { key: :archived, title: 'Archived', active: true, count: 1 },
          { key: :deleted, title: 'Deleted', active: false, count: 0 }
        ]
      end

      it 'returns a list of campaigns satisfying the condition' do
        expect(service.call).to include(campaigns: archived_campaigns)
      end

      it 'returns the list of filters (with active)' do
        expect(service.call).to include(filters: expected_filters)
      end
    end

    context 'when filter is nil' do
      let(:filter) { nil }

      let(:expected_filters) do
        [
          { key: :draft, title: 'Draft', active: true, count: 3 },
          { key: :sent, title: 'Sent', active: false, count: 1 },
          { key: :archived, title: 'Archived', active: false, count: 1 },
          { key: :deleted, title: 'Deleted', active: false, count: 0 }
        ]
      end

      it 'returns a list of draft campaigns (default filter)' do
        expect(service.call).to include(campaigns: draft_campaigns)
      end

      it 'returns the list of filters (with default active)' do
        expect(service.call).to include(filters: expected_filters)
      end
    end

    context 'when filter is unknown' do
      let(:filter) { 'abyrvalg' }

      let(:expected_filters) do
        [
          { key: :draft, title: 'Draft', active: true, count: 3 },
          { key: :sent, title: 'Sent', active: false, count: 1 },
          { key: :archived, title: 'Archived', active: false, count: 1 },
          { key: :deleted, title: 'Deleted', active: false, count: 0 }
        ]
      end

      it 'returns a list of draft campaigns (default filter)' do
        expect(service.call).to include(campaigns: draft_campaigns)
      end

      it 'returns the list of filters (with default active)' do
        expect(service.call).to include(filters: expected_filters)
      end
    end
  end
end
