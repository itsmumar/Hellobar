describe SenderAddress do
  let!(:sender_address) { create :sender_address }

  it { is_expected.to validate_presence_of :site_id }
  it { is_expected.to validate_presence_of :address_one }
  it { is_expected.not_to validate_presence_of :address_two }
  it { is_expected.to validate_presence_of :city }
  it { is_expected.to validate_presence_of :postal_code }

  context 'if in USA' do
    before { allow(subject).to receive(:country).and_return('US') }
    it { should validate_presence_of(:state) }
  end
end
