describe ConditionSerializer do
  let(:condition) { create(:condition, :date_between) }

  it 'should include segment' do
    serializer = ConditionSerializer.new(condition)
    expect(serializer.as_json)
      .to eq(
        id: condition.id,
        rule_id: condition.rule_id,
        segment: condition.segment,
        operand: condition.operand,
        value: condition.value
      )
  end
end
