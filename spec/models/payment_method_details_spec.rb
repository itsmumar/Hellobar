require 'spec_helper'

describe PaymentMethodDetails do
  fixtures :all
  it 'should be read-only' do
    d = PaymentMethodDetails.create
    d.data = {foo: 'bar'}
    lambda{d.save}.should raise_error(ActiveRecord::ReadOnlyRecord)
    lambda{d.destroy}.should raise_error(ActiveRecord::ReadOnlyRecord)
  end
end

describe CyberSourceCreditCard do
  fixtures :all
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

  it 'should remove all non-standard fields from data' do
    cc = CyberSourceCreditCard.new(payment_method: payment_methods(:joeys))

    cc.data = VALID_DATA.merge('foo' => 'bar')
    cc.save!
    cc = CyberSourceCreditCard.find(cc.id)
    cc.data['foo'].should be_nil
  end

  it 'should not store the full credit card number' do
    cc = CyberSourceCreditCard.new(payment_method: payment_methods(:joeys))
    cc.data = VALID_DATA
    cc.save!
    cc.data['number'].should == 'XXXX-XXXX-XXXX-1111'
    cc = CyberSourceCreditCard.find(cc.id)
    cc.data['number'].should == 'XXXX-XXXX-XXXX-1111'
  end

  it 'should not store the cvv' do
    cc = CyberSourceCreditCard.new(payment_method: payment_methods(:joeys))
    cc.data = VALID_DATA
    cc.save!
    cc.data['verification_value'].should == nil
    cc = CyberSourceCreditCard.find(cc.id)
    cc.data['verification_value'].should == nil
  end

  it 'should store the cybersource_token' do
    cc = CyberSourceCreditCard.new(payment_method: payment_methods(:joeys))
    cc.data = VALID_DATA
    cc.data['token'].should be_nil
    cc.save!
    cc.data['token'].should_not be_nil
    cc = CyberSourceCreditCard.find(cc.id)
    cc.data['token'].should_not be_nil
  end

  it 'should provide a good name' do
    cc = CyberSourceCreditCard.new(payment_method: payment_methods(:joeys))
    cc.data = VALID_DATA
    cc.name.should == 'Visa ending in 1111'
    cc.save!
    cc = CyberSourceCreditCard.find(cc.id)
    cc.name.should == 'Visa ending in 1111'
  end

  it 'should re-use an existing token if set on the same payment_method' do
    p = payment_methods(:joeys)
    cc1 = CyberSourceCreditCard.new(data: VALID_DATA, payment_method: p)
    cc1.save!
    cc1 = CyberSourceCreditCard.find(cc1.id)
    cc1.data['token'].should_not be_nil
    cc1.cybersource_profile['cardExpirationYear'].should == '2016'
    # Now update the year
    cc2 = CyberSourceCreditCard.new(data: VALID_DATA.merge('year' => '2017'), payment_method: p)
    cc2.save!
    cc2 = CyberSourceCreditCard.find(cc2.id)
    cc2.data['token'].should_not be_nil
    # Should have re-used the same token
    cc2.data['token'].should == cc1.data['token']
    # Should have updated the name for both credit cards
    cc1 = CyberSourceCreditCard.find(cc1.id)
    cc2 = CyberSourceCreditCard.find(cc2.id)
    cc2.cybersource_profile['cardExpirationYear'].should == '2017'
    cc1.cybersource_profile['cardExpirationYear'].should == '2017'
  end

  it 'should let you charge the card and return the transaction ID' do
    success, response = CyberSourceCreditCard.create!(data: VALID_DATA, payment_method: payment_methods(:joeys)).charge(100)
    success.should be_true
    response.should_not be_nil
    response.should match(/^.*?;.*?;.*$/)
  end

  it 'should validate the data' do
    # Should be valid
    cc = CyberSourceCreditCard.new(data: VALID_DATA, payment_method: payment_methods(:joeys))
    cc.errors.messages.should == {}
    cc.should be_valid

    CyberSourceCreditCard.new(payment_method: payment_methods(:joeys)).should_not be_valid
    missing = VALID_DATA.merge({})
    missing.delete(:first_name)
    CyberSourceCreditCard.new(data: missing, payment_method: payment_methods(:joeys)).should_not be_valid
    cc = CyberSourceCreditCard.new(data: INVALID_DATA, payment_method: payment_methods(:joeys))
    cc.should_not be_valid
  end

  it 'should not require the state field for foreign addresses' do
    # Should be valid
    cc = CyberSourceCreditCard.new(data: FOREIGN_DATA, payment_method: payment_methods(:joeys))
    cc.errors.messages.should == {}
    cc.should be_valid
  end

  it 'should let you refund a payment' do
    credit_card = CyberSourceCreditCard.create!(data: VALID_DATA, payment_method: payment_methods(:joeys))
    charge_success, charge_response = credit_card.charge(100)
    charge_success.should be_true
    charge_response.should_not be_nil
    refund_success, refund_response = credit_card.refund(50, charge_response)
    refund_success.should be_true
    refund_response.should_not be_nil
    refund_response.should_not == charge_response
  end
end
