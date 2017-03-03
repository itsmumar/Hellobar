class Coupon < ActiveRecord::Base
  REFERRAL_LABEL = 'for_referrals'
  REFERRAL_AMOUNT = Subscription::Pro.defaults[:monthly_amount]

  scope :internal, -> { where(public: false) }

  has_many :coupon_uses

  def self.for_referrals
    internal.where(label: REFERRAL_LABEL).first
  end
end
