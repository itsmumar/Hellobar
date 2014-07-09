class UrlCondition < Condition
  serialize :value, String

  def self.include_url(url)
    UrlCondition.new operand: Condition::OPERANDS[:includes],
                     value: url
  end

  def self.exclude_url(url)
    UrlCondition.new operand: Condition::OPERANDS[:excludes],
                     value: url
  end

  def include_url?
    operand == Condition::OPERANDS[:includes]
  end
end
