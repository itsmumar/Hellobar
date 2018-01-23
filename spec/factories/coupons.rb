FactoryGirl.define do
  factory :coupon do
    label Coupon::REFERRAL_LABEL
    amount Coupon::REFERRAL_AMOUNT
    public false

    trait :referral

    trait :promotional do
      label Coupon::PROMOTIONAL_LABEL
      trial_period 30
      public true
    end
  end
end
