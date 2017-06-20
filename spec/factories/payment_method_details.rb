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

    factory :cyber_source_credit_card, class: 'CyberSourceCreditCard' do
      transient do
        token 'token'
        user nil
      end
      payment_method { user ? create(:payment_method, user: user) : create(:payment_method) }

      data { create :payment_data, token: token }
    end
  end

  factory :payment_data, class: Hash do
    skip_create

    number '4111 1111 1111 1111'
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
    token nil

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

    trait :foreign do
      number '4242 4242 4242 4242'
      first_name 'Tobias'
      last_name 'Luetke'
      verification_value '123'
      city 'London'
      zip 'W10 6TH'
      address '149 Freston Rd'
      country 'GB'
    end
  end
end
