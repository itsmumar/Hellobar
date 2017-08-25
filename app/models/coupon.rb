class Coupon < ActiveRecord::Base
  REFERRAL_LABEL = 'for_referrals'.freeze
  REFERRAL_AMOUNT = Subscription::Pro.defaults[:monthly_amount]

  PROMOTIONAL_LABEL = 'NEILPATELHB2017'.freeze
  PROMOTIONAL_AMOUNT = Subscription::Pro.defaults[:monthly_amount] * 2

  has_many :coupon_uses

  validates :label, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :internal, -> { where(public: false) }

  def self.for_referrals
    internal.find_by(label: REFERRAL_LABEL)
  end

  def self.promotional
    find_by label: PROMOTIONAL_LABEL
  end
end
