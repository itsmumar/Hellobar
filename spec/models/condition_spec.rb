require 'spec_helper'

describe Condition, 'validating the value format' do
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

    it 'is valid when the value is an Array with 2 elements' do
      condition = Condition.new operand: 'between', value: ['one', 'two'], rule: Rule.new

      condition.should be_valid
    end
  end
end
