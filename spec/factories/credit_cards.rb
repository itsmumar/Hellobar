FactoryGirl.define do
  factory :credit_card do
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
    sequence(:token) { |i| "token-#{ i }" }
    user nil
  end
end
