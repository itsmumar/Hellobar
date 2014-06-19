class UrlCondition < Condition
  # { include_url: <DateTime>, exclude_url: <DateTime> }
  serialize :value, Hash

  def self.create_include_url(url)
    UrlCondition.create operand: Condition::OPERANDS[:includes],
                        value: { 'include_url' => url }
  end

  def self.create_exclude_url(url)
    UrlCondition.create operand: Condition::OPERANDS[:excludes],
                        value: { 'exclude_url' => url }
  end
end
