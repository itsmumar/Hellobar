class Bar < ActiveRecord::Base
  belongs_to :rule

  validates :goal, presence: true
end
