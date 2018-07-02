FactoryBot.define do
  factory :admin do
    transient do
      password 'password'
    end

    sequence(:email) { |i| "admin#{ i }@hellobar.com" }
    initial_password { password }
    password_hashed { encrypt_password(password) }
    session_token 'aisodgjoai'
    session_last_active { Time.current }

    trait :locked do
      locked true
    end
  end
end
