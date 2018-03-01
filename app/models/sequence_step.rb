class SequenceStep < ApplicationRecord
  acts_as_paranoid

  belongs_to :executable, polymorphic: true
  belongs_to :sequence

  validates :delay, presence: true
end
