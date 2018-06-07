class AffiliateInformation < ApplicationRecord
  self.table_name = 'affiliate_information'

  belongs_to :user

  validates :visitor_identifier, presence: true
  validates :affiliate_identifier, presence: true
end

