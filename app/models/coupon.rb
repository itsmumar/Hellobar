class Coupon < ActiveRecord::Base
  REFERRAL_LABEL = 'for_referrals'.freeze
  REFERRAL_AMOUNT = Subscription::Pro.defaults[:monthly_amount]

  has_many :coupon_uses, dependent: :destroy

  validates :label, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :internal, -> { where(public: false) }

  def self.for_referrals
    internal.find_by(label: REFERRAL_LABEL)
  end
end
