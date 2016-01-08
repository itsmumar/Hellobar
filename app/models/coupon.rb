class Coupon < ActiveRecord::Base
  scope :internal, lambda { where(label: nil, available_uses: nil) }

  has_many :coupon_uses
end