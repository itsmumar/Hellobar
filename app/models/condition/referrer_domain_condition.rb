class ReferrerDomainCondition < Condition
  validates :operand, presence: true,
                      inclusion: {
                        in: %w{ is is_not includes does_not_include }
                      }
end
