describe CyberSourceCreditCard do
  let(:payment_method) { create :payment_method }
  let(:data) { create :payment_data, token: 'token' }
  let!(:credit_card) { create :cyber_source_credit_card, data: data, token: 'token' }

  describe '#delete_token' do
    it 'deletes token when it is present' do
      expect { credit_card.delete_token }.to change(credit_card, :token).to(nil)
    end
  end

  describe '#grace_period' do
    it 'is 15.days' do
      expect(credit_card.grace_period).to eql 15.days
    end
  end

  describe '#data=' do
    it 'sanitizes credit card number' do
      credit_card.data = data.merge(number: '4242424242424242')
      expect(credit_card.data['number']).to eq 'XXXX-XXXX-XXXX-4242'
    end

    context 'with extra fields' do
      it 'removes them from data' do
        credit_card.data = data.merge('foo' => 'bar')
        expect(credit_card.data['foo']).to be_nil
      end
    end
  end
end
