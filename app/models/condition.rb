class Condition < ActiveRecord::Base
  self.inheritance_column = 'segment'

  # class name: Hello::Segments::User key
  SEGMENTS = {
    'DeviceCondition' => 'dv',
    'DateCondition' => 'dt',
    'UrlCondition' => 'pu'
  }

  # stored value: displayed value
  OPERANDS = {
    is_after: 'is after',
    is_before: 'is before',
    is_between: 'is between',
    is: 'is',
    is_not: 'is not',
    includes: 'includes',
    does_not_include: 'does not include'
  }.with_indifferent_access

  belongs_to :rule, inverse_of: :conditions

  validates :rule, association_exists: true

  def operand
    value = read_attribute(:operand)

    value.to_sym if value
  end

  def to_sentence
    "#{segment_data[:name]} #{OPERANDS[operand]} #{value}"
  end

  def segment_key
    SEGMENTS[segment]
  end

  def segment_data
    Hello::Segments::User.find { |s| s[:key] == segment_key } || {}
  end
end
