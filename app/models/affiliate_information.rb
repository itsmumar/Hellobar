class AffiliateInformation < ApplicationRecord
  belongs_to :user
  belongs_to :partner, foreign_key: :affiliate_identifier, primary_key: :affiliate_identifier

  validates :visitor_identifier, presence: true
  validates :affiliate_identifier, presence: true
end
