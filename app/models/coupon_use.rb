class CouponUse < ApplicationRecord
  belongs_to :bill
  belongs_to :coupon

  validates :bill, presence: true
  validates :coupon, presence: true
end
