class DateCondition < Condition
  validates :operand, presence: true,
                      inclusion: {
                        in: %w{ is is_not before after between }
                      }

  def self.from_params(start_date, end_date)
    return unless [start_date, end_date].any?(&:present?)

    if [start_date, end_date].all?(&:present?)
      operand = 'between'
      value = [start_date, end_date]
    elsif start_date.present?
      operand = 'after'
      value = start_date
    elsif end_date.present?
      operand = 'before'
      value = end_date
    end

    new(operand: operand, value: value)
  end
end
