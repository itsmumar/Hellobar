module ReferralTokenizable
  extend ActiveSupport::Concern

  included do
    has_one :referral_token, as: :tokenizable
    after_create :create_referral_token
  end
end
