class Bar < ActiveRecord::Base
  belongs_to :rule_set

  validates :goal, presence: true

  scope :paused, -> { where(paused: true) }
  scope :active, -> { where(paused: false) }
end
