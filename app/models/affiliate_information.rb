class AffiliateInformation < ApplicationRecord
  belongs_to :user

  validates :visitor_identifier, presence: true
  validates :affiliate_identifier, presence: true
end

