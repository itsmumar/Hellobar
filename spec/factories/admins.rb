FactoryGirl.define do
  factory :admin do
    email { Faker::Internet.email }
    initial_password { Faker::PhoneNumber.cell_phone }
    password_hashed "fb61e3a4fae3674ee2a6a473bf915ac20950d064ff43e34d6e423874b97cbca1"
    password_last_reset { Time.now - 5.minutes }
    session_access_token "owigjoia"
    session_token "aisodgjoai"
    session_last_active { Time.now }
  end
end
