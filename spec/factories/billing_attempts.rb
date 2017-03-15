FactoryGirl.define do
  factory :billing_attempt do
    payment_method_details factory: :always_successful_billing_details
    status :success

    trait :success

    trait :failed do
      payment_method_details factory: :always_fails_payment_method_details
      status :failed
    end
  end
end
