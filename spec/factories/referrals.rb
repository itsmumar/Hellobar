FactoryGirl.define do
  factory :referral do
    sequence(:email) { |i| "referral#{ i }@hellobar.com" }
    sender { create(:user) }
    state 'signed_up'
  end
end
