FactoryGirl.define do
  factory :payment_method do
    user

    after(:create) do |payment_method|
      create(:always_successful_billing_details, payment_method: payment_method)
    end

    trait :fails do
      after(:create) do |payment_method|
        create(:always_fails_payment_method_details, payment_method: payment_method)
      end
    end
  end
end
