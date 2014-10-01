class DeviceCondition < Condition
  validates :operand, presence: true,
                      inclusion: {
                        in: %w{ is is_not }
                      }
end
