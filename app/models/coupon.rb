class Coupon < ActiveRecord::Base
  REFERRAL_LABEL='for_referrals'

  scope :internal, lambda { where(public: false) }

  has_many :coupon_uses

  def self.for_referrals
    internal.where(label: REFERRAL_LABEL).first
  end
end