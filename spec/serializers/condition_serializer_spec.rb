require 'spec_helper'

describe ConditionSerializer do
  fixtures :all

  let(:condition) { conditions(:date_between) }
  let(:c) { condition }

  it 'should include segment' do
    serializer = ConditionSerializer.new(condition)
    expect(serializer.as_json).to eq({
      id: condition.id,
      rule_id: nil,
      segment: condition.segment,
      operand: condition.operand,
      value: condition.value,
      custom_segment: nil,
      data_type: nil
    })
  end
end
