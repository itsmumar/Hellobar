describe Campaign do
  it { is_expected.to validate_presence_of :site }
  it { is_expected.to validate_presence_of :contact_list }
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :from_name }
  it { is_expected.to validate_presence_of :from_email }
  it { is_expected.to validate_presence_of :subject }
  it { is_expected.to validate_presence_of :body }
  it { is_expected.to validate_presence_of :status }

  it { is_expected.to validate_inclusion_of(:status).in_array Campaign::STATUSES }
  it { is_expected.to allow_value('abc@example.com').for :from_email }
  it { is_expected.not_to allow_value('example').for :from_email }
  it { is_expected.not_to allow_value('@example').for :from_email }

  it 'is a paranoia protected model', :freeze do
    campaign = create :campaign

    campaign.destroy

    expect(campaign).to be_persisted
    expect(campaign).to be_deleted
    expect(campaign.deleted_at).to eq Time.current
  end

  describe '#sent!' do
    subject(:campaign) { create(:campaign, :new) }

    it 'updates status' do
      campaign.sent!
      expect(campaign).to be_sent
    end

    it 'updates sent_at' do
      campaign.sent!
      expect(campaign.sent_at).to be_present
    end
  end

  describe '#archived!' do
    subject(:campaign) { create(:campaign, :sent) }

    it 'updates status' do
      campaign.archived!
      expect(campaign).to be_archived
    end

    it 'updates archived_at' do
      campaign.archived!
      expect(campaign.archived_at).to be_present
    end

    context 'when campaign can not be archived' do
      subject(:campaign) { create(:campaign, :new) }

      it 'raises an error' do
        expect { campaign.archived! }.to
          raise_error(Campaign::InvalidTransition, Campaign::INVALID_TRANSITION_TO_ARCHIVED)
      end
    end
  end
end
