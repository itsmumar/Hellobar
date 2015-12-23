FactoryGirl.define do
  factory :referral do
    email { Faker::Internet.email }
    sender_id { Faker::Number.positive }
    state { 'signed_up' }
  end
end
