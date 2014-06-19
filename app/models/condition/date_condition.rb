class DateCondition < Condition
  # { start_date: <DateTime>, end_date: <DateTime> }
  serialize :value, Hash

  def self.create_from_params(start_date, end_date)
    return unless [start_date, end_date].any?(&:present?)

    if [start_date, end_date].all?(&:present?)
      operand = Condition::OPERANDS[:is_between]
      value = { 'start_date' => start_date, 'end_date' => end_date }
    elsif start_date.present?
      operand = Condition::OPERANDS[:is_after]
      value = { 'start_date' => start_date }
    elsif end_date.present?
      operand = Condition::OPERANDS[:is_before]
      value = { 'end_date' => end_date }
    end

    create operand: operand,
           value: value
  end
end
