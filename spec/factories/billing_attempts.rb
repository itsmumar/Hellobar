FactoryBot.define do
  factory :billing_attempt do
    status BillingAttempt::SUCCESSFUL

    trait :success

    trait :failed do
      status BillingAttempt::STATE_FAILED
      response 'General decline of the card'
    end
  end
end
