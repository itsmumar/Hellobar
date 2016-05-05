FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password { Faker::Internet.password }

    trait :with_free_subscription do
      after(:create) do |user|
        create(:free_subscription, user: user)
      end
    end

    trait :with_pro_subscription do
      after(:create) do |user|
        create(:pro_subscription, user: user)
      end
    end

  end
end
