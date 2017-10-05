FactoryGirl.define do
  factory :billing_attempt do
    status :successful

    trait :success

    trait :failed do
      status :failed
      response 'General decline of the card'
    end
  end
end
