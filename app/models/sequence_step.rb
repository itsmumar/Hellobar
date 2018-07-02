class SequenceStep < ApplicationRecord
  EXECUTABLE_TYPES = [Email.name].freeze

  acts_as_paranoid

  belongs_to :executable, polymorphic: true
  belongs_to :sequence

  validates :delay, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :executable, presence: true
  validates :executable_type, inclusion: { in: EXECUTABLE_TYPES }

  delegate :site, :contact_list_id, to: :sequence, allow_nil: true

  def statistics
    FetchEmailStatistics.new(self).call
  end
end
