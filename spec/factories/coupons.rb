FactoryGirl.define do
  factory :coupon do
    label Coupon::REFERRAL_LABEL
    amount Coupon::REFERRAL_AMOUNT
    public false

    trait :referral

    trait :promotional do
      label Coupon::PROMOTIONAL_LABEL
      amount Coupon::PROMOTIONAL_AMOUNT

      public true
    end
  end
end
