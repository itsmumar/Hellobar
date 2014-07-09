class Condition < ActiveRecord::Base
  self.inheritance_column = 'segment'

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
end
