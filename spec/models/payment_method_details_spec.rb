require 'spec_helper'

describe PaymentMethodDetails do
  it 'should be read-only' do
    d = PaymentMethodDetails.create
    d.data = { foo: 'bar' }
    expect { d.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { d.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end

describe CyberSourceCreditCard do
  VALID_DATA = {
    number: '4111111111111111',
    month: '8',
    year: '2016',
    first_name: 'Tobias',
    last_name: 'Luetke',
    verification_value: '123',
    city: 'Eugene',
    state: 'OR',
    zip: '97408',
    address1: '123 Some St',
    country: 'USA'
  }.freeze
  INVALID_DATA = VALID_DATA.clone.merge(number: '123412341234')
  FOREIGN_DATA = {
    number: '4111111111111111',
    month: '8',
    year: '2016',
    first_name: 'Tobias',
    last_name: 'Luetke',
    verification_value: '123',
    city: 'London',
    zip: 'W10 6TH',
    address1: '149 Freston Rd',
    country: 'United Kingdom'
  }.freeze

  let(:payment_method) { create(:payment_method) }

  it 'should remove all non-standard fields from data' do
    cc = CyberSourceCreditCard.new(payment_method: payment_method)

    cc.data = VALID_DATA.merge('foo' => 'bar')
    cc.save!
    cc = CyberSourceCreditCard.find(cc.id)
    expect(cc.data['foo']).to be_nil
  end

  it 'should not store the full credit card number' do
    cc = CyberSourceCreditCard.new(payment_method: payment_method)
    cc.data = VALID_DATA
    cc.save!
    expect(cc.data['number']).to eq('XXXX-XXXX-XXXX-1111')
    cc = CyberSourceCreditCard.find(cc.id)
    expect(cc.data['number']).to eq('XXXX-XXXX-XXXX-1111')
  end

  it 'should not store the cvv' do
    cc = CyberSourceCreditCard.new(payment_method: payment_method)
    cc.data = VALID_DATA
    cc.save!
    expect(cc.data['verification_value']).to be_nil
    cc = CyberSourceCreditCard.find(cc.id)
    expect(cc.data['verification_value']).to be_nil
  end

  it 'should store the cybersource_token' do
    cc = CyberSourceCreditCard.new(payment_method: payment_method)
    cc.data = VALID_DATA
    expect(cc.data['token']).to be_nil
    cc.save!
    expect(cc.data['token']).not_to be_nil
    cc = CyberSourceCreditCard.find(cc.id)
    expect(cc.data['token']).not_to be_nil
  end

  it 'should provide a good name' do
    cc = CyberSourceCreditCard.new(payment_method: payment_method)
    cc.data = VALID_DATA
    expect(cc.name).to eq('Visa ending in 1111')
    cc.save!
    cc = CyberSourceCreditCard.find(cc.id)
    expect(cc.name).to eq('Visa ending in 1111')
  end

  it 'should re-use an existing token if set on the same payment_method' do
    p = payment_method
    cc1 = CyberSourceCreditCard.new(data: VALID_DATA, payment_method: p)
    cc1.save!
    cc1 = CyberSourceCreditCard.find(cc1.id)
    expect(cc1.data['token']).not_to be_nil
    expect(cc1.cybersource_profile['cardExpirationYear']).to eq('2016')
    # Now update the year
    cc2 = CyberSourceCreditCard.new(data: VALID_DATA.merge('year' => '2017'), payment_method: p)
    cc2.save!
    cc2 = CyberSourceCreditCard.find(cc2.id)
    expect(cc2.data['token']).not_to be_nil
    # Should have re-used the same token
    expect(cc2.data['token']).to eq(cc1.data['token'])
    # Should have updated the name for both credit cards
    cc1 = CyberSourceCreditCard.find(cc1.id)
    cc2 = CyberSourceCreditCard.find(cc2.id)
    expect(cc2.cybersource_profile['cardExpirationYear']).to eq('2017')
    expect(cc1.cybersource_profile['cardExpirationYear']).to eq('2017')
  end

  it 'should let you charge the card and return the transaction ID' do
    success, response = CyberSourceCreditCard.create!(data: VALID_DATA, payment_method: payment_method).charge(100)
    expect(success).to be_true
    expect(response).not_to be_nil
    expect(response).to match(/^.*?;.*?;.*$/)
  end

  it 'should validate the data' do
    # Should be valid
    cc = CyberSourceCreditCard.new(data: VALID_DATA, payment_method: payment_method)
    expect(cc.errors.messages).to eq({})
    expect(cc).to be_valid

    expect(CyberSourceCreditCard.new(payment_method: payment_method)).not_to be_valid
    missing = VALID_DATA.merge({})
    missing.delete(:first_name)
    expect(CyberSourceCreditCard.new(data: missing, payment_method: payment_method)).not_to be_valid
    cc = CyberSourceCreditCard.new(data: INVALID_DATA, payment_method: payment_method)
    expect(cc).not_to be_valid
  end

  it 'should not require the state field for foreign addresses' do
    # Should be valid
    cc = CyberSourceCreditCard.new(data: FOREIGN_DATA, payment_method: payment_method)
    expect(cc.errors.messages).to eq({})
    expect(cc).to be_valid
  end

  it 'should let you refund a payment' do
    credit_card = CyberSourceCreditCard.create!(data: VALID_DATA, payment_method: payment_method)
    charge_success, charge_response = credit_card.charge(100)
    expect(charge_success).to be_true
    expect(charge_response).not_to be_nil
    refund_success, refund_response = credit_card.refund(50, charge_response)
    expect(refund_success).to be_true
    expect(refund_response).not_to be_nil
    expect(refund_response).not_to eq(charge_response)
  end
end
