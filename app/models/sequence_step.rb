class SequenceStep < ApplicationRecord
  VALID_EXECUTABLE_TYPES = [Campaign.name].freeze

  acts_as_paranoid

  belongs_to :executable, polymorphic: true
  belongs_to :sequence

  validates :delay, presence: true
  validates :executable, presence: true
  validates :executable_type, inclusion: { in: VALID_EXECUTABLE_TYPES }
end
