FactoryGirl.define do
  factory :payment_method do
    user

    after(:create) do |payment_method|
      create(:cyber_source_credit_card, payment_method: payment_method)
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
