require 'spec_helper'

describe DateCondition, '::from_params' do
  it 'creates a between condition when both start_date and end_date are present' do
    condition = DateCondition.from_params('start', 'end')

    condition.operand.should == :is_between
    condition.value['start_date'].should == 'start'
    condition.value['end_date'].should == 'end'
  end

  it 'creates a start_date condition when only start_date is present' do
    condition = DateCondition.from_params('start', '')

    condition.operand.should == :is_after
    condition.value['start_date'].should == 'start'
    condition.value['end_date'].should be_nil
  end

  it 'creates a end_date condition when only end_date is present' do
    condition = DateCondition.from_params('', 'end')

    condition.operand.should == :is_before
    condition.value['end_date'].should == 'end'
    condition.value['start_date'].should be_nil
  end

  it 'does nothing when neither start nor end date are present' do
    DateCondition.from_params('', '').should be_nil
  end
end

describe DateCondition, '#to_sentence' do
  it "converts 'is between' conditions to sentences" do
    DateCondition.from_params('7/6', '7/13').to_sentence.should == "date is between 7/6 and 7/13"
  end

  it "converts 'is before' conditions to sentences" do
    DateCondition.from_params('', '7/13').to_sentence.should == "date is before 7/13"
  end

  it "converts 'is after' conditions to sentences" do
    DateCondition.from_params('7/6', '').to_sentence.should == "date is after 7/6"
  end
end
