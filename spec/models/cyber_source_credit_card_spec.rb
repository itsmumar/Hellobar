describe CyberSourceCreditCard do
  let(:payment_method) { create :payment_method }
  let(:data) { create :payment_data }
  let(:credit_card) { CyberSourceCreditCard.new data: data }
  let(:gateway) { double('CyberSourceGateway') }

  describe '#delete_token' do
    let!(:credit_card) { create :cyber_source_credit_card }

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

  describe '#name' do
    let(:credit_card) { CyberSourceCreditCard.new data: { number: '4242424242421234' } }

    specify { expect(credit_card.name).to eql 'Credit Card ending in 1234' }

    context 'without number' do
      let(:credit_card) { CyberSourceCreditCard.new data: { number: '' } }

      specify { expect(credit_card.name).to eql 'Credit Card ending in ???' }
    end

    context 'with brand' do
      let(:credit_card) { CyberSourceCreditCard.new data: { brand: 'visa', number: '4242424242421234' } }

      specify { expect(credit_card.name).to eql 'Visa ending in 1234' }

      context 'and without number' do
        let(:credit_card) { CyberSourceCreditCard.new data: { brand: 'visa', number: '' } }

        specify { expect(credit_card.name).to eql 'Visa ending in ???' }
      end
    end
  end

  describe '#charge', :freeze do
    let(:credit_card) { create :cyber_source_credit_card }
    let(:order_id) { "#{ credit_card.payment_method.id }-#{ Time.current.to_i }" }
    let(:response) { double(success?: true, authorization: '1') }

    it 'calls gateway.purchase' do
      expect { credit_card.charge(100) }
        .to make_gateway_call(:purchase).with(10_000, credit_card.formatted_token, order_id: order_id)
    end

    context 'when invalid amount' do
      it 'raises ArgumentError' do
        expect { credit_card.charge(-1) }.to raise_error(ArgumentError, 'Invalid amount: -1')
        expect { credit_card.charge(nil) }.to raise_error(ArgumentError, 'Invalid amount: nil')
      end
    end
  end

  describe '#refund', :freeze do
    let(:credit_card) { create :cyber_source_credit_card }
    let(:order_id) { "#{ credit_card.payment_method.id }-#{ Time.current.to_i }" }

    it 'calls gateway.refund' do
      expect { credit_card.refund(100, '1') }
        .to make_gateway_call(:refund).with(10_000, '1')
    end

    context 'when invalid amount' do
      it 'raises ArgumentError' do
        expect { credit_card.refund(-1, 'id') }.to raise_error(ArgumentError, 'Invalid amount: -1')
        expect { credit_card.refund(nil, 'id') }.to raise_error(ArgumentError, 'Invalid amount: nil')
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
