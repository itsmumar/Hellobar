FactoryGirl.define do
  factory :referral do
    sequence(:email) { |i| "referral#{ i }@hellobar.com" }
    sender factory: :user
    site
    state 'signed_up'
    body 'Some text...'
  end
end
