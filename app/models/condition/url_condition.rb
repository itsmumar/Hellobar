class UrlCondition < Condition
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
end
