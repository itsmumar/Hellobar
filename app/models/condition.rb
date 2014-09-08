class Condition < ActiveRecord::Base
  self.inheritance_column = 'segment'

  SEGMENTS = {
    'CountryCondition' => 'country',
    'DeviceCondition' => 'device',
    'DateCondition' => 'date',
    'UrlCondition' => 'url'
  }

  OPERANDS = {
    is_after: 'is after',
    is_before: 'is before',
    is_between: 'is between',
    is: 'is',
    is_not: 'is not',
    includes: 'includes',
    excludes: 'excludes'
  }.with_indifferent_access

  belongs_to :rule

  validates :rule, association_exists: true

  def to_sentence
    "#{SEGMENTS[segment]} #{OPERANDS[operand]} #{value}"
  end

  def short_segment
    segment.gsub(/Condition$/, '').underscore.downcase
  end
end
