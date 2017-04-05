describe Lead do
  context 'when challenge is "more_emails"' do
    let(:lead) { build(:lead, challenge: 'more_emails') }

    specify { expect(lead).to be_valid }
  end

  context 'when challenge is "more_sales"' do
    let(:lead) { build(:lead, challenge: 'more_sales') }

    specify { expect(lead).to be_valid }
  end

  context 'when challenge is "conversion_optimization"' do
    let(:lead) { build(:lead, challenge: 'conversion_optimization') }

    specify { expect(lead).to be_valid }
  end
end
