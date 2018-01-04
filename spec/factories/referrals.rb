FactoryGirl.define do
  factory :referral do
    sequence(:email) { |i| "referral#{ i }@hellobar.com" }
    sender factory: :user
    site
    state 'sent'
    body 'Some text...'

    trait :signed_up do
      state Referral::SIGNED_UP
    end

    trait :installed do
      state Referral::INSTALLED
    end
  end
end
