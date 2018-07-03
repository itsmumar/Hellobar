class AffiliateCommission < ActiveRecord::Base
  belongs_to :bill

  validates :identifier, presence: true
  validates :bill, presence: true
end
