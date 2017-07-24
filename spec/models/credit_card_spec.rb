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

  describe '#charge', :freeze do
    let(:response) { double(success?: true, authorization: '1') }

    it 'calls gateway.purchase' do
      expect { credit_card.charge(100) }
        .to make_gateway_call(:purchase).with(10_000, credit_card)
    end

    context 'when invalid amount' do
      it 'raises ArgumentError' do
        expect { credit_card.charge(-1) }.to raise_error(ArgumentError, 'Invalid amount: -100.0')
        expect { credit_card.charge(0) }.to raise_error(ArgumentError, 'Invalid amount: 0.0')
        expect { credit_card.charge(nil) }.to raise_error(ArgumentError, 'Invalid amount: 0.0')
      end
    end

    context 'when address is "card-declined"' do
      let!(:credit_card) { create :credit_card, token: 'token', address: 'card-declined' }

      it 'returns unsuccessfull response' do
        expect(credit_card.charge(10)).to match_array [false, 'Decline - Insufficient funds in the account.']
      end
    end
  end

  describe '#refund', :freeze do
    let(:credit_card) { create :credit_card }
    let(:order_id) { "#{ credit_card.payment_method.id }-#{ Time.current.to_i }" }

    it 'calls gateway.refund' do
      expect { credit_card.refund(100, '1') }
        .to make_gateway_call(:refund).with(10_000, '1')
    end

    context 'when invalid amount' do
      it 'raises ArgumentError' do
        expect { credit_card.refund(-1, 'id') }.to raise_error(ArgumentError, 'Invalid amount: -100.0')
        expect { credit_card.refund(0, 'id') }.to raise_error(ArgumentError, 'Invalid amount: 0.0')
        expect { credit_card.refund(nil, 'id') }.to raise_error(ArgumentError, 'Invalid amount: 0.0')
      end
    end

    context 'when transaction id is blank' do
      it 'raises error' do
        expect { credit_card.refund(100, '') }
          .to raise_error('Can not refund without original transaction ID')
      end
    end
  end
end
