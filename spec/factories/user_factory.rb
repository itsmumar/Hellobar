FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password { Faker::Internet.password }

    after(:build) do |user|
      user.class.skip_callback(:create, :after, :add_to_infusionsoft_in_background)
    end

    trait :with_free_subscription do
      after(:create) do |user|
        create :subscription, :free, user: user
      end
    end

    trait :with_pro_subscription do
      after(:create) do |user|
        create :subscription, :pro, user: user
      end
    end

    trait :with_pro_managed_subscription do
      after(:create) do |user|
        create :subscription, :pro_managed, user: user
      end
    end
  end
end
