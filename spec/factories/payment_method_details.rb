FactoryGirl.define do
  factory :payment_method_details do
    factory :always_successful_billing_details, class: 'AlwaysSuccessfulPaymentMethodDetails' do
    end

    factory :always_fails_payment_method_details, class: 'AlwaysFailsPaymentMethodDetails' do
    end

    factory :cyber_source_credit_card, class: 'FakeCyberSourceCreditCard' do
      payment_method

      data do
        {
          'number' => '4012 8888 8888 1881',
          'month' => 12,
          'year' => Date.current.year + 1,
          'first_name' => 'John',
          'last_name' => 'Doe',
          'address1' => 'Sunset Blv 205',
          'city' => 'San Francisco',
          'state' => 'CA',
          'zip' => '94016',
          'country' => 'US',
          'brand' => 'visa',
          'verification_value' => '777',
          'token' => 'cc_token'
        }
      end
    end
  end
end
