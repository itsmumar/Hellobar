require 'spec_helper'


describe PaymentMethodDetails do
  it "should be read-only" do
    d = PaymentMethodDetails.create
    d.data = {foo: "bar"}
    lambda{d.save}.should raise_error(ActiveRecord::ReadOnlyRecord)
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
    city: "Eugene",
    state: "OR",
    zip: "97408",
    address1: "123 Some St",
    country: "USA"
  }.freeze
  INVALID_DATA = VALID_DATA.clone.merge(number: '1234123412341234')

  it "should remove all non-standard fields from data" do
    cc = CyberSourceCreditCard.new
    cc.data = VALID_DATA.merge("foo" => "bar")
    cc.save
    cc = CyberSourceCreditCard.find(cc.id)
    cc.data["foo"].should be_nil
  end

  it "should not store the full credit card number" do
    cc = CyberSourceCreditCard.new
    cc.data = VALID_DATA
    cc.save
    cc.data["number"].should == "XXXX-XXXX-XXXX-1111"
    cc = CyberSourceCreditCard.find(cc.id)
    cc.data["number"].should == "XXXX-XXXX-XXXX-1111"
  end

  it "should store the cybersource_token" do
    cc = CyberSourceCreditCard.new
    cc.data = VALID_DATA
    cc.data["token"].should be_nil
    cc.save
    cc.data["token"].should_not be_nil
    cc = CyberSourceCreditCard.find(cc.id)
    cc.data["token"].should_not be_nil
  end

  it "should provide a good name" do
    cc = CyberSourceCreditCard.new
    cc.data = VALID_DATA
    cc.name.should == "Visa ending in 1111"
    cc.save
    cc = CyberSourceCreditCard.find(cc.id)
    cc.name.should == "Visa ending in 1111"
  end

  it "should re-use an existing token if set on the same payment_method" do
    p = PaymentMethod.new
    cc1 = CyberSourceCreditCard.new(data: VALID_DATA)
    p.details << cc1
    p.save
    cc1 = CyberSourceCreditCard.find(cc1.id)
    cc1.data["token"].should_not be_nil
    cc1.cybersource_profile["cardExpirationYear"].should == "2016"
    # Now update the year
    cc2 = CyberSourceCreditCard.new(data: VALID_DATA.merge("year" => "2017"))
    p.details << cc2
    p.save
    cc2 = CyberSourceCreditCard.find(cc2.id)
    cc2.data["token"].should_not be_nil
    # Should have re-used the same token
    cc2.data["token"].should == cc1.data["token"]
    # Should have updated the name for both credit cards
    cc1 = CyberSourceCreditCard.find(cc1.id)
    cc2 = CyberSourceCreditCard.find(cc2.id)
    cc2.cybersource_profile["cardExpirationYear"].should == "2017"
    cc1.cybersource_profile["cardExpirationYear"].should == "2017"
  end

  it "should let you charge the card and return the transaction ID" do
    success, response = CyberSourceCreditCard.create(data: VALID_DATA).charge(100)
    success.should be_true
    response.should_not be_nil
    response.should match(/^.*?;.*?;.*$/)
  end
end
