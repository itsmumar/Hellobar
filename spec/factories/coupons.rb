FactoryGirl.define do
  factory :coupon do
    label Coupon::REFERRAL_LABEL
    amount Coupon::REFERRAL_AMOUNT
    public false

    trait :referral
  end
end
