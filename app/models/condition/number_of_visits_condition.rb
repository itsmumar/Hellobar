class NumberOfVisitsCondition < Condition
  validates :operand, presence: true,
                      inclusion: {
                        in: %w{ is is_not less_than greater_than between }
                      }
end
