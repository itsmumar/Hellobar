FactoryGirl.define do
  factory :billing_attempt do
    status :success

    trait :success

    trait :failed do
      status :failed
    end
  end
end
