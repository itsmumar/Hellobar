FactoryGirl.define do
  factory :payment_method do
    user

    after(:create) do |payment_method|
      create(:cyber_source_credit_card, payment_method: payment_method, token: 'token')
    end

    trait :success do
      after(:create) do |payment_method|
        create(:always_successful_billing_details, payment_method: payment_method)
      end
    end

    trait :fails do
      after(:create) do |payment_method|
        create(:always_fails_payment_method_details, payment_method: payment_method)
      end
    end

    trait :cyber_source_credit_card do
      transient do
        token 'token'
      end

      after(:create) do |payment_method, evaluator|
        create(:cyber_source_credit_card, payment_method: payment_method, token: evaluator.token)
      end
    end
  end
end
