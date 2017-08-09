describe CyberSourceGateway do
  let(:gateway) { CyberSourceGateway.new }
  let(:credit_card) { create :cyber_source_credit_card }

  it 'is in test mode' do
    expect(gateway).to be_test
  end

  describe '#purchase' do
    let!(:request) do
      stub_request(:post, 'https://ics2wstesta.ic3.com/commerce/1.x/transactionProcessor')
        .with(body: %r{<grandTotalAmount>9.99</grandTotalAmount>})
    end

    it 'makes purchase to cybersource' do
      expect(gateway.purchase(9.99, credit_card))
        .to respond_to(:success?, :authorization, :message)
      expect(request).to have_been_made
    end
  end

  describe '#refund' do
    let!(:request) do
      stub_request(:post, 'https://ics2wstesta.ic3.com/commerce/1.x/transactionProcessor')
        .with(body: %r{<grandTotalAmount>9.99</grandTotalAmount>})
    end

    it 'makes request to cybersource' do
      expect(gateway.refund(9.99, 'transaction ID'))
        .to respond_to(:success?, :authorization, :message)
      expect(request).to have_been_made
    end
  end
end
