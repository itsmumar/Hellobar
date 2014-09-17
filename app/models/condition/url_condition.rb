class UrlCondition < Condition
  serialize :value

  def self.include_url(url)
    UrlCondition.new operand: :includes,
                     value: url
  end

  def self.does_not_include_url(url)
    UrlCondition.new operand: :does_not_include,
                     value: url
  end

  def include_url?
    operand == :includes
  end

  def to_sentence
    case operand
    when :includes
      "URL includes #{value}"
    when :does_not_include
      "URL does not include #{value}"
    end
  end
end
