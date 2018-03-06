class SequenceStepSerializer < ActiveModel::Serializer
  attributes :id, :delay, :executable_type, :executable_id
end
