class SequenceStepSerializer < ActiveModel::Serializer
  attributes :id, :name, :sequence_id, :delay, :executable_id, :executable_type
end
