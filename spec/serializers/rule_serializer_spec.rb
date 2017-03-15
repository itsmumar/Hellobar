require 'spec_helper'

describe RuleSerializer do
  let!(:condition) { create(:condition, :date_between) }
  let!(:rule) { condition.rule.reload }

  it 'should include segment' do
    serializer = RuleSerializer.new(rule)

    expect(serializer.as_json).to eq(
      id: rule.id,
      site_id: rule.site_id,
      name: rule.name,
      match: rule.match,
      priority: rule.priority,
      description: rule.to_sentence,
      editable: true,

      conditions: [{
        id: condition.id,
        rule_id: rule.id,
        segment: condition.segment,
        operand: condition.operand,
        value: condition.value,
        custom_segment: nil,
        data_type: nil
      }]
    )
  end
end
