class ConditionSerializer < ActiveModel::Serializer
  attributes :id, :rule_id, :segment, :operand, :value, :is_between

  def is_between
    operand == :is_between
  end
end
