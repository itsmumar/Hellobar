class UrlCondition < Condition
  before_validation :clear_blank_values

  validates :operand, presence: true,
                      inclusion: {
                        in: %w{ is is_not includes does_not_include }
                      }

  def to_sentence
    if value.count > 2
      "#{segment_data[:name]} #{OPERANDS[operand]} #{value.first} or #{value.count - 1} other URLs"
    elsif value.count == 2
      "#{segment_data[:name]} #{OPERANDS[operand]} #{value.first} or 1 other URL"
    else
      "#{segment_data[:name]} #{OPERANDS[operand]} #{value.first}"
    end
  end

  private

  def clear_blank_values
    self.value = value.select{|v| !v.blank?}
  end
end
