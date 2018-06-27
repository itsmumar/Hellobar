class AffiliateCommission < ActiveRecord::Base
  self.primary_key = :identifier

  belongs_to :bill

  validates :identifier, presence: true
  validates :bill, presence: true
end
