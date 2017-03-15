FactoryGirl.define do
  factory :referral_token do
    tokenizable factory: :user
  end
end
