FactoryGirl.define do
  factory :coupon do
    factory :referral_coupon, parent: :coupon do
      label Coupon::REFERRAL_LABEL
      amount Coupon::REFERRAL_AMOUNT
    end
  end
end
