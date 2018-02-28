class Sequence < ApplicationRecord
  acts_as_paranoid

  belongs_to :contact_list

  validates :name, presence: true
  validates :contact_list, presence: true
end
