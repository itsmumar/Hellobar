describe CreditCard do
  let!(:credit_card) { create :credit_card, token: 'token' }
  let(:gateway) { double('CyberSourceGateway') }

  describe '#grace_period' do
    it 'is 15.days' do
      expect(credit_card.grace_period).to eql 15.days
    end
  end

  describe '#number=' do
    it 'sanitizes credit card number' do
      credit_card.number = '4242424242424242'
      expect(credit_card.number).to eq 'XXXX-XXXX-XXXX-4242'
    end
  end

  describe '#formatted_token' do
    it 'wrap token with ;' do
      expect(credit_card.formatted_token).to eq ';token;'
    end
  end

  describe '#order_id' do
    it 'is id and timestamp', :freeze do
      expect(credit_card.order_id).to eq "#{ credit_card.id }-#{ Time.current.to_i }"
    end
  end
end
