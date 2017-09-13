FactoryGirl.define do
  factory :billing_attempt do
    status :success

    trait :success

    trait :failed do
      status :failed
      response 'General decline of the card'
    end
  end
end
