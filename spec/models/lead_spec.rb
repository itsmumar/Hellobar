describe Lead do
  it { is_expected.to validate_presence_of :industry }
  it { is_expected.to validate_presence_of :job_role }
  it { is_expected.to validate_presence_of :company_size }
  it { is_expected.to validate_presence_of :estimated_monthly_traffic }
  it { is_expected.to validate_presence_of :first_name }
  it { is_expected.to validate_presence_of :last_name }
  it { is_expected.to validate_presence_of :challenge }
  it { is_expected.to validate_inclusion_of(:challenge).in_array(%w(capture\ more\ emails generate\ more\ sales conversion\ optimization)) }
  it { is_expected.not_to validate_presence_of(:phone_number) }

  context 'with interested = true' do
    subject { build(:lead, :interested) }
    it { is_expected.to validate_presence_of(:phone_number) }
  end

  context 'on create' do
    let!(:user) { create :user, first_name: 'Foo', last_name: 'Bar' }

    it 'update user first_name and last_name' do
      expect { create(:lead, first_name: 'FName', last_name: 'LName', user: user) }
        .to change(user, :first_name).to('FName')
        .and change(user, :last_name).to('LName')
    end
  end
end
