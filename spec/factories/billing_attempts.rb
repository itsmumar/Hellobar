FactoryGirl.define do
  factory :billing_attempt do
    payment_method_details factory: :always_successful_billing_details

    trait :success do
      payment_method_details factory: :always_successful_billing_details
      status :success
    end

    trait :failed do
      payment_method_details factory: :always_fails_payment_method_details
      status :failed
    end
  end
end
