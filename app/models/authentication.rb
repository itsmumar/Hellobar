class Authentication < ApplicationRecord
  belongs_to :user

  validates :user, presence: true
  validates :provider, presence: true
end
