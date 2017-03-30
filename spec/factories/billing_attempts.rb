FactoryGirl.define do
  factory :billing_attempt do
    status :success

    payment_method_details factory: :always_successful_billing_details

    trait :success

    trait :failed do
      status :failed

      payment_method_details factory: :always_fails_payment_method_details
    end
  end
end
