class SequenceStep < ApplicationRecord
  VALID_EXECUTABLE_TYPES = [Campaign.name, Email.name].freeze

  acts_as_paranoid

  belongs_to :executable, polymorphic: true
  belongs_to :sequence

  validates :delay, presence: true, numericality: { only_integer: true }
  validates :executable, presence: true
  validates :executable_type, inclusion: { in: VALID_EXECUTABLE_TYPES }
end
