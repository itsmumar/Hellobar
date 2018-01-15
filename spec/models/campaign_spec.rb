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

  describe '#archived!' do
    subject(:campaign) { create(:campaign) }

    before do
      campaign.archived!
    end

    it 'updates status' do
      expect(campaign).to be_archived
    end

    it 'updates archived_at' do
      expect(campaign.archived_at).to be_present
    end
  end
end
