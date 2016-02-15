class ConditionSerializer < ActiveModel::Serializer
  attributes :id, :rule_id, :segment, :operand, :value, :custom_segment, :data_type
end
