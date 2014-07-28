class RuleSerializer < ActiveModel::Serializer
  attributes :id, :site_id, :name, :priority, :match, :description

  has_many :conditions, serializer: ConditionSerializer

  def description
    object.to_sentence
  end
end
