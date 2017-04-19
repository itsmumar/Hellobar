describe Lead do
  it { is_expected.to validate_presence_of :industry }
  it { is_expected.to validate_presence_of :job_role }
  it { is_expected.to validate_presence_of :company_size }
  it { is_expected.to validate_presence_of :estimated_monthly_traffic }
  it { is_expected.to validate_presence_of :first_name }
  it { is_expected.to validate_presence_of :last_name }
  it { is_expected.to validate_presence_of :challenge }
  it { is_expected.to validate_inclusion_of(:challenge).in_array(%w[capture\ more\ emails generate\ more\ sales conversion\ optimization]) }
  it { is_expected.not_to validate_presence_of(:phone_number) }

  context 'with interested = true' do
    subject { build(:lead, :interested) }
    it { is_expected.to validate_presence_of(:phone_number) }
  end
end
