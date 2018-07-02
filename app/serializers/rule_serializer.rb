class RuleSerializer < ActiveModel::Serializer
  attributes :id, :site_id, :name, :match, :description, :editable

  has_many :conditions, serializer: ConditionSerializer

  def description
    object.to_sentence
  end
end
