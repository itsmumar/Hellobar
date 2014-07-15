class DateCondition < Condition
  # { start_date: <DateTime>, end_date: <DateTime> }
  serialize :value, Hash

  def self.from_params(start_date, end_date)
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

    new(operand: operand, value: value.with_indifferent_access)
  end

  def to_sentence
    case operand
    when OPERANDS[:is_between]
      "date is between #{value['start_date']} and #{value['end_date']}"
    when OPERANDS[:is_after]
      "date is after #{value['start_date']}"
    when OPERANDS[:is_before]
      "date is before #{value['end_date']}"
    end
  end
end
