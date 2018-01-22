class CouponUse < ApplicationRecord
  belongs_to :bill
  belongs_to :coupon
  has_one :site, through: :bill, dependent: :nullify

  validates :bill, presence: true
  validates :coupon, presence: true

  def self.for_site(site)
    joins(:site).where(sites: { id: site.id })
  end
end
