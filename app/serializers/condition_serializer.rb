class ConditionSerializer < ActiveModel::Serializer
  attributes :id, :rule_id, :segment, :operand, :value
end
