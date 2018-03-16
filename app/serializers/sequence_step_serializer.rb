class SequenceStepSerializer < ActiveModel::Serializer
  attributes :id, :sequence_id, :delay, :executable_type, :executable_id
end
