class UrlCondition < Condition
  serialize :value, String

  def self.create_include_url(url)
    UrlCondition.create operand: Condition::OPERANDS[:includes],
                        value: url
  end

  def self.create_exclude_url(url)
    UrlCondition.create operand: Condition::OPERANDS[:excludes],
                        value: url
  end

  def include_url?
    operand == Condition::OPERANDS[:includes]
  end
end
