class CouponUse < ActiveRecord::Base
  belongs_to :bill
  belongs_to :coupon
end
