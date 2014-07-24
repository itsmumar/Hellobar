class RuleSerializer < ActiveModel::Serializer
  attributes :id, :site_id, :name, :priority, :match

  has_many :conditions, serializer: ConditionSerializer
end
