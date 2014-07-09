class Condition < ActiveRecord::Base
  self.inheritance_column = 'segment'

  SEGMENTS = %w{ country device date url }

  OPERANDS = {
    is_after: 'is after',
    is_before: 'is before',
    is_between: 'is between',
    is: 'is',
    is_not: 'is not',
    includes: 'includes',
    excludes: 'excludes'
  }

  belongs_to :rule

  validates :rule, association_exists: true

  def to_sentence
    "#{segment} #{operand} #{value}"
  end
end
