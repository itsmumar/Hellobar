require 'spec_helper'

describe RuleSerializer do

  fixtures :rules, :conditions

  let(:rule) { rules(:zombo) }

  it 'should include segment' do
    condition = conditions(:date_between)
    rule.conditions << condition

    serializer = RuleSerializer.new(rule)

    expect(serializer.as_json).to eq({
      id: rule.id,
      site_id: rule.site_id,
      name: rule.name,
      match: rule.match,
      priority: rule.priority,
      description: rule.to_sentence,

      conditions: [{
        id: condition.id,
        rule_id: rule.id,
        segment: condition.short_segment,
        operand: condition.operand,
        value: condition.value
      }]
    })
  end
end
