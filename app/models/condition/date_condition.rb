class DateCondition < Condition
  # { start_date: <DateTime>, end_date: <DateTime> }
  serialize :value

  include ComparableDate

  def self.from_params(start_date, end_date)
    return unless [start_date, end_date].any?(&:present?)

    if [start_date, end_date].all?(&:present?)
      operand = 'is_between'
      value = { 'start_date' => start_date, 'end_date' => end_date }
    elsif start_date.present?
      operand = 'is_after'
      value = { 'start_date' => start_date }
    elsif end_date.present?
      operand = 'is_before'
      value = { 'end_date' => end_date }
    end

    new(operand: operand, value: value.with_indifferent_access)
  end

  def to_sentence
    if operand.to_s == 'is_between'
      "date is between #{value['start_date']} and #{value['end_date']}"
    elsif operand.to_s == 'is_after'
      "date is after #{value['start_date']}"
    elsif operand.to_s == 'is_before'
      "date is before #{value['end_date']}"
    end
  end
end
