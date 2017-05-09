FactoryGirl.define do
  factory :payment_method_details do
    data do
      {
        'first_name' => 'John',
        'last_name' => 'Doe'
      }
    end

    factory :always_successful_billing_details, class: 'AlwaysSuccessfulPaymentMethodDetails' do
    end

    factory :always_fails_payment_method_details, class: 'AlwaysFailsPaymentMethodDetails' do
    end

    factory :cyber_source_credit_card, class: 'FakeCyberSourceCreditCard' do
      payment_method

      data factory: :payment_data
    end
  end

  factory :payment_data, class: Hash do
    skip_create

    number '4012 8888 8888 1881'
    month 12
    year { Date.current.year + 1 }
    first_name 'John'
    last_name 'Doe'
    address 'Sunset Blv 205'
    city 'San Francisco'
    state 'CA'
    zip '94016'
    country 'US'
    brand 'visa'
    verification_value '777'
    token 'cc_token'

    initialize_with do
      {
        'number' => number,
        'month' => month,
        'year' => year,
        'first_name' => first_name,
        'last_name' => last_name,
        'address' => address,
        'address1' => address,
        'city' => city,
        'state' => state,
        'zip' => zip,
        'country' => country,
        'brand' => brand,
        'verification_value' => verification_value,
        'token' => token
      }
    end
  end
end
