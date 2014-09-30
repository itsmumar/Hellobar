require 'spec_helper'

describe DateCondition, '::from_params' do
  it 'creates a between condition when both start_date and end_date are present' do
    condition = DateCondition.from_params('start', 'end')

    condition.operand.should == 'between'
    condition.value.should == ['start', 'end']
  end

  it 'creates a start_date condition when only start_date is present' do
    condition = DateCondition.from_params('start', '')

    condition.operand.should == 'after'
    condition.value.should == 'start'
  end

  it 'creates a end_date condition when only end_date is present' do
    condition = DateCondition.from_params('', 'end')

    condition.operand.should == 'before'
    condition.value.should == 'end'
  end

  it 'does nothing when neither start nor end date are present' do
    DateCondition.from_params('', '').should be_nil
  end
end

describe DateCondition, '#to_sentence' do
  it "converts 'is between' conditions to sentences" do
    DateCondition.from_params('7/6', '7/13').to_sentence.should == "Date is between 7/6 and 7/13"
  end

  it "converts 'is before' conditions to sentences" do
    DateCondition.from_params('', '7/13').to_sentence.should == "Date is before 7/13"
  end

  it "converts 'is after' conditions to sentences" do
    DateCondition.from_params('7/6', '').to_sentence.should == "Date is after 7/6"
  end
end
