describe PaymentMethodDetails do
  it 'is read-only' do
    d = PaymentMethodDetails.create
    d.data = { foo: 'bar' }
    expect { d.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { d.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end

describe CyberSourceCreditCard, :new_vcr do
  let(:year) { 2.years.from_now.year.to_s }

  let(:valid_data) { create :payment_data }

  let(:invalid_data) { valid_data.merge(number: '123412341234') }

  let(:foreign_data) { create :payment_data, :foreign }

  let(:payment_method) { create(:payment_method, :success) }

  describe '#save' do
    it 'removes all non-standard fields from data' do
      cc = CyberSourceCreditCard.new(payment_method: payment_method)

      cc.data = valid_data.merge('foo' => 'bar')
      cc.save!
      cc = CyberSourceCreditCard.find(cc.id)
      expect(cc.data['foo']).to be_nil
    end

    it 'does not store the full credit card number' do
      cc = CyberSourceCreditCard.new(payment_method: payment_method)
      cc.data = valid_data
      cc.save!
      expect(cc.data['number']).to eq('XXXX-XXXX-XXXX-1111')
      cc = CyberSourceCreditCard.find(cc.id)
      expect(cc.data['number']).to eq('XXXX-XXXX-XXXX-1111')
    end

    it 'does not store the cvv' do
      cc = CyberSourceCreditCard.new(payment_method: payment_method)
      cc.data = valid_data
      cc.save!
      expect(cc.data['verification_value']).to be_nil
      cc = CyberSourceCreditCard.find(cc.id)
      expect(cc.data['verification_value']).to be_nil
    end

    it 'stores the cybersource_token' do
      cc = CyberSourceCreditCard.new(payment_method: payment_method)
      cc.data = valid_data
      expect(cc.data['token']).to be_nil
      cc.save!
      expect(cc.data['token']).not_to be_nil
      cc = CyberSourceCreditCard.find(cc.id)
      expect(cc.data['token']).not_to be_nil
    end
  end

  describe '#name' do
    it 'provides a good name' do
      cc = CyberSourceCreditCard.new(payment_method: payment_method)
      cc.data = valid_data
      expect(cc.name).to eq('Visa ending in 1111')
      cc.save!
      cc = CyberSourceCreditCard.find(cc.id)
      expect(cc.name).to eq('Visa ending in 1111')
    end
  end

  context 'when set on the same payment_method' do
    it 're-uses an existing token' do
      p = payment_method
      cc1 = CyberSourceCreditCard.new(data: valid_data, payment_method: p)
      cc1.save!
      cc1 = CyberSourceCreditCard.find(cc1.id)
      expect(cc1.data['token']).not_to be_nil
      # Now update the year
      cc2 = CyberSourceCreditCard.new(data: valid_data.merge('year' => year), payment_method: p)
      cc2.save!
      cc2 = CyberSourceCreditCard.find(cc2.id)
      expect(cc2.data['token']).not_to be_nil
      # Should have re-used the same token
      expect(cc2.data['token']).to eq(cc1.data['token'])
    end
  end

  describe '#charge' do
    it 'returns the transaction ID' do
      success, response = CyberSourceCreditCard.create!(data: valid_data, payment_method: payment_method).charge(100)
      expect(success).to be_truthy
      expect(response).not_to be_nil
      expect(response).to match(/^.*?;.*?;.*$/)
    end
  end

  context 'with foreign card' do
    it 'does not require state for foreign addresses' do
      cc = CyberSourceCreditCard.new(data: foreign_data, payment_method: payment_method)
      expect(cc.errors.messages).to eq({})
      expect(cc).to be_valid
    end
  end

  describe '#refund' do
    it 'refunds a payment' do
      credit_card = CyberSourceCreditCard.create!(data: valid_data, payment_method: payment_method)
      charge_success, charge_response = credit_card.charge(100)
      expect(charge_success).to be_truthy
      expect(charge_response).not_to be_nil
      refund_success, refund_response = credit_card.refund(50, charge_response)
      expect(refund_success).to be_truthy
      expect(refund_response).not_to be_nil
      expect(refund_response).not_to eq(charge_response)
    end
  end
end
