class Sequence < ApplicationRecord
  acts_as_paranoid

  has_one :site, through: :contact_list, dependent: :nullify
  belongs_to :contact_list

  has_many :steps, class_name: 'SequenceStep', dependent: :destroy, inverse_of: :sequence

  validates :name, presence: true
  validates :contact_list, presence: true
end
