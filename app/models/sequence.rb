class Sequence < ApplicationRecord
  acts_as_paranoid

  belongs_to :contact_list

  has_many :sequence_steps, dependent: :destroy, inverse_of: :sequence

  validates :name, presence: true
  validates :contact_list, presence: true
end
