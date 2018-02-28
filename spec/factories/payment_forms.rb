FactoryBot.define do
  factory :payment_form_params, class: Hash do
    skip_create

    number '4111 1111 1111 1111'
    expiration { format '%s/%s', Date.current.month, Date.current.year + 1 }
    name 'John Doe'
    address 'Sunset Blv 205'
    city 'San Francisco'
    state 'CA'
    zip '94016'
    country 'US'
    verification_value '777'

    initialize_with do
      {
        number: number,
        expiration: expiration,
        verification_value: verification_value,
        name: name,
        address: address,
        city: city,
        state: state,
        zip: zip,
        country: country
      }
    end
  end

  factory :payment_form do
    skip_create

    params factory: :payment_form_params

    initialize_with { PaymentForm.new params }
  end
end
