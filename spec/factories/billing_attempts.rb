FactoryGirl.define do
  factory :billing_attempt do
    status :success

    payment_method_details factory: :cyber_source_credit_card

    trait :success

    trait :failed do
      status :failed

      payment_method_details factory: :cyber_source_credit_card
    end
  end
end
