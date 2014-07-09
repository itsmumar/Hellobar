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

  def to_sentence
    case operand
    when OPERANDS[:includes]
      "URL includes #{value}"
    when OPERANDS[:excludes]
      "URL does not include #{value}"
    end
  end
end
