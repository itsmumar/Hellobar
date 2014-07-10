class ConditionSerializer < ActiveModel::Serializer
  attributes :id, :rule_id, :segment, :operand, :value

  def segment
    object.short_segment
  end
end
