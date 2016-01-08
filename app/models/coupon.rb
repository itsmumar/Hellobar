class Coupon < ActiveRecord::Base
  scope :internal, lambda { where(label: nil, available_uses: nil) }
end
