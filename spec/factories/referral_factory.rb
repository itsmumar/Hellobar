FactoryGirl.define do
  factory :referral do
    email { Faker::Internet.email }
    sender { create(:user) }
    state { 'signed_up' }
  end
end
