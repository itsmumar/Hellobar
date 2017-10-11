describe EmailCampaign do
  it { is_expected.to validate_presence_of :site }
  it { is_expected.to validate_presence_of :contact_list }
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :from_name }
  it { is_expected.to validate_presence_of :from_email }
  it { is_expected.to validate_presence_of :subject }
  it { is_expected.to validate_presence_of :body }
  it { is_expected.to validate_presence_of :status }

  it { is_expected.to validate_inclusion_of(:status).in_array EmailCampaign::STATUSES }
  it { is_expected.to allow_value('abc@example.com').for :from_email }
  it { is_expected.not_to allow_value('example').for :from_email }
  it { is_expected.not_to allow_value('@example').for :from_email }

  it 'is a paranoia protected model', :freeze do
    email_campaign = create :email_campaign

    email_campaign.destroy

    expect(email_campaign).to be_persisted
    expect(email_campaign).to be_deleted
    expect(email_campaign.deleted_at).to eq Time.current
  end
end
