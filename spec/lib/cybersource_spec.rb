describe CyberSourceCreditCard do
  let(:payment_method) { create :payment_method }
  let(:data) { { 'token' => 'my_cool_token', number: '4242424242424242' } }
  let(:credit_card) { CyberSourceCreditCard.new data: data }

  describe '#token_present?' do
    it 'returns true when data is present, and token is present' do
      cscc = CyberSourceCreditCard.new data: { 'token' => 'my_cool_token' }
      expect(cscc.token_present?).to be_truthy
    end
    it 'returns false when data is present, and token is not present' do
      cscc = CyberSourceCreditCard.new data: {}
      expect(cscc.token_present?).to be_falsey
    end
    it 'returns false when data is not present' do
      cscc = CyberSourceCreditCard.new
      expect(cscc.token_present?).to be_falsey
    end
  end

  describe '#delete_token' do
    it 'deletes token when it is present' do
      cscc = CyberSourceCreditCard.new data: { 'token' => 'my_cool_token' }
      cscc.save(validate: false)
      cscc.reload.delete_token
      expect(cscc.reload.token).to be_nil
    end
  end

  describe '#card' do
    let(:data) do
      {
        token: 'my_cool_token',
        number: '4242424242424242',
        first_name: 'FirstName',
        last_name: 'LastName',
        month: '01',
        year: '2020',
        brand: 'visa'
      }
    end
    let(:credit_card) { CyberSourceCreditCard.new data: data }
    let(:card) { credit_card.card }

    it 'returns ActiveMerchant::Billing::CreditCard' do
      expect(card).to be_a ActiveMerchant::Billing::CreditCard
      expect(card.number).to eql data[:number]
      expect(card.first_name).to eql data[:first_name]
      expect(card.last_name).to eql data[:last_name]
      expect(card.month).to eql data[:month].to_i
      expect(card.year).to eql data[:year].to_i
      expect(card.brand).to eql data[:brand]
    end
  end

  context 'validation', :freeze do
    let(:data) { { 'token' => 'my_cool_token', number: '4242424242424242' } }
    let(:credit_card) { CyberSourceCreditCard.new payment_method: payment_method, data: data }

    context 'without brand' do
      let(:data) { { token: 'my_cool_token', state: 'CA' } }

      it 'is invalid' do
        expect(credit_card).to be_invalid
      end
    end

    context 'without token' do
      let(:data) { { brand: 'visa', state: 'CA' } }

      it 'is invalid' do
        expect(credit_card).to be_invalid
      end
    end

    context 'without state' do
      let(:data) { { token: 'my_cool_token', brand: 'visa' } }

      it 'is invalid' do
        expect(credit_card).to be_invalid
      end
    end

    context 'without previous token' do
      let(:response) { double(success?: true, params: { 'subscriptionID' => '1' }) }
      let(:params) do
        {
          order_id: "#{ payment_method.id }-#{ Time.current.to_i }",
          email: "user#{ payment_method.user_id }@hellobar.com",
          address: { city: nil, state: nil, zip: nil, address1: nil, country: nil }
        }
      end

      it 'sends store request to CyberSource gateway' do
        expect(HB::CyberSource.gateway)
          .to receive(:store).with(instance_of(ActiveMerchant::Billing::CreditCard), hash_including(params)).and_return(response)
        credit_card.save
      end
    end

    context 'with previous token' do
      let(:response) { double(success?: true, params: { 'subscriptionID' => '1' }) }
      # let(:credit_card) { CyberSourceCreditCard.new data: { 'token' => 'my_cool_token', number: '4242424242424242' } }
      let(:params) do
        {
          order_id: "#{ payment_method.id }-#{ Time.current.to_i }",
          email: "user#{ payment_method.user_id }@hellobar.com",
          address: { city: nil, state: nil, zip: nil, address1: nil, country: nil }
        }
      end

      before do
        allow(credit_card).to receive(:previous_token).and_return('token')
      end

      it 'sends update request to CyberSource gateway' do
        expect(HB::CyberSource.gateway)
          .to receive(:update).with(';token;', instance_of(ActiveMerchant::Billing::CreditCard), hash_including(params)).and_return(response)
        credit_card.save
      end
    end
  end

  describe '#grace_period' do
    it 'is 15.days' do
      expect(credit_card.grace_period).to eql 15.days
    end
  end

  context 'with brand' do
    let(:credit_card) { CyberSourceCreditCard.new data: { brand: 'visa', number: '4242424242421234' } }

    it 'is used to generate name' do
      expect(credit_card.name).to eql 'Visa ending in 1234'
    end
  end

  describe '#charge', :freeze do
    let(:credit_card) { create :cyber_source_credit_card }
    let(:order_id) { "#{ credit_card.payment_method.id }-#{ Time.current.to_i }" }
    let(:response) { double(success?: true, authorization: '1') }

    it 'calls gateway.purchase' do
      expect(HB::CyberSource.gateway)
        .to receive(:purchase).with(10_000, ';cc_token;', order_id: order_id).and_return(response)
      credit_card.charge(100)
    end
  end

  describe '#refund', :freeze do
    let(:credit_card) { create :cyber_source_credit_card }
    let(:order_id) { "#{ credit_card.payment_method.id }-#{ Time.current.to_i }" }
    let(:response) { double(success?: true, authorization: '1') }

    it 'calls gateway.refund' do
      expect(HB::CyberSource.gateway)
        .to receive(:refund).with(10_000, '1').and_return(response)
      credit_card.refund(100, '1')
    end
  end
end
