class DateCondition < Condition
  serialize :value

  def self.from_params(start_date, end_date)
    return unless [start_date, end_date].any?(&:present?)

    if [start_date, end_date].all?(&:present?)
      operand = 'is_between'
      value = [start_date, end_date]
    elsif start_date.present?
      operand = 'is_after'
      value = [start_date]
    elsif end_date.present?
      operand = 'is_before'
      value = [end_date]
    end

    new(operand: operand, value: value)
  end

  def to_sentence
    if operand.to_s == 'is_between'
      "date is between #{value.first} and #{value.last}"
    elsif operand.to_s == 'is_after'
      "date is after #{value.first}"
    elsif operand.to_s == 'is_before'
      "date is before #{value.first}"
    end
  end
end
