FactoryGirl.define do
  factory :payment_method do
    user

    after(:create) do |payment_method|
      create(:always_successful_billing_details, payment_method: payment_method)
    end
  end
end
