class Condition < ActiveRecord::Base
  self.inheritance_column = 'segment'

  # stored value: displayed value
  SEGMENTS = {
    'CountryCondition' => 'country',
    'DeviceCondition' => 'device',
    'DateCondition' => 'date',
    'UrlCondition' => 'url'
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
    "#{SEGMENTS[segment]} #{OPERANDS[operand]} #{value}"
  end

  def short_segment
    segment.gsub(/Condition$/, '').underscore.downcase
  end
end
