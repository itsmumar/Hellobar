require 'spec_helper'

describe DateCondition, '::from_params' do
  it 'creates a between condition when both start_date and end_date are present' do
    condition = DateCondition.from_params('start', 'end')

    condition.operand.should == Condition::OPERANDS[:is_between]
    condition.value['start_date'].should == 'start'
    condition.value['end_date'].should == 'end'
  end

  it 'creates a start_date condition when only start_date is present' do
    condition = DateCondition.from_params('start', '')

    condition.operand.should == Condition::OPERANDS[:is_after]
    condition.value['start_date'].should == 'start'
    condition.value['end_date'].should be_nil
  end

  it 'creates a end_date condition when only end_date is present' do
    condition = DateCondition.from_params('', 'end')

    condition.operand.should == Condition::OPERANDS[:is_before]
    condition.value['end_date'].should == 'end'
    condition.value['start_date'].should be_nil
  end

  it 'does nothing when neither start nor end date are present' do
    DateCondition.from_params('', '').should be_nil
  end
end
