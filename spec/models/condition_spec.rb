require 'spec_helper'

describe Condition, 'validating the value format' do
  fixtures :all

  it "clears empty values during validation" do
    condition = Condition.new(
      rule: rules(:zombo),
      operand: "is",
      value: ["/foo", "/bar", ""],
      segment: "UrlCondition"
    )

    condition.should be_valid
    condition.value.should == ["/foo", "/bar"]
  end

  context 'the operand is NOT "between"' do
    it 'is NOT valid when the value is a non-String object' do
      condition = Condition.new operand: 'is', value: ['array'], rule: Rule.new

      condition.should_not be_valid
    end

    it 'is valid when the value is a String' do
      condition = Condition.new operand: 'is', value: 'string', rule: Rule.new

      condition.should be_valid
    end
  end

  context 'the operand is "between"' do
    it 'is NOT valid when the value is a non-Array object' do
      condition = Condition.new operand: 'between', value: 'string value', rule: Rule.new

      condition.should_not be_valid
    end

    it 'is NOT valid when the value is an Array with 1 element' do
      condition = Condition.new operand: 'between', value: ['one'], rule: Rule.new

      condition.should_not be_valid
    end

    it 'is NOT valid when the value is an array with 2 empty values' do
      condition = Condition.new operand: 'between', value: ['', ''], rule: Rule.new

      condition.should_not be_valid
    end

    it 'is valid when the value is an Array with 2 elements' do
      condition = Condition.new operand: 'between', value: ['one', 'two'], rule: Rule.new

      condition.should be_valid
    end
  end
end

describe Condition, '::date_condition_from_params' do
  it 'creates a between condition when both start_date and end_date are present' do
    condition = Condition.date_condition_from_params('start', 'end')

    condition.operand.should == 'between'
    condition.value.should == ['start', 'end']
  end

  it 'creates a start_date condition when only start_date is present' do
    condition = Condition.date_condition_from_params('start', '')

    condition.operand.should == 'after'
    condition.value.should == 'start'
  end

  it 'creates a end_date condition when only end_date is present' do
    condition = Condition.date_condition_from_params('', 'end')

    condition.operand.should == 'before'
    condition.value.should == 'end'
  end

  it 'does nothing when neither start nor end date are present' do
    Condition.date_condition_from_params('', '').should be_nil
  end
end

describe Condition, '#to_sentence' do
  context "is a DateCondition" do
    it "converts 'is between' conditions to sentences" do
      Condition.date_condition_from_params('7/6', '7/13').to_sentence.should == "Date is between 7/6 and 7/13"
    end

    it "converts 'is before' conditions to sentences" do
      Condition.date_condition_from_params('', '7/13').to_sentence.should == "Date is before 7/13"
    end

    it "converts 'is after' conditions to sentences" do
      Condition.date_condition_from_params('7/6', '').to_sentence.should == "Date is after 7/6"
    end
  end
end
