FactoryGirl.define do
  factory :admin do
    sequence(:email) { |i| "admin#{ i }@hellobar.com" }
    initial_password 'password'
    password_hashed { encrypt_password('password') }
    password_last_reset { Time.current - 5.minutes }
    session_token 'aisodgjoai'
    session_last_active { Time.current }

    trait :locked do
      locked true
    end
  end
end
