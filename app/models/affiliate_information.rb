class AffiliateInformation < ApplicationRecord
  belongs_to :user

  validates :visitor_identifier, presence: true
  validates :affiliate_identifier, presence: true

  def partner
    @partner ||= Partner.find_by(affiliate_identifier: affiliate_identifier)
  end
end
