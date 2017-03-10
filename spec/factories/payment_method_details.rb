FactoryGirl.define do
  factory :payment_method_details do
  end

  factory :always_successful_billing_details, parent: :payment_method_details, class: 'AlwaysSuccessfulPaymentMethodDetails' do
  end
end
