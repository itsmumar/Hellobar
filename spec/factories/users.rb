FactoryGirl.define do
  factory :user do
    first_name 'FirstName'
    last_name 'LastName'
    sequence(:email) { |i| "user#{ i }@hellobar.com" }
    password 'password'

    after(:build) do |user|
      user.class.skip_callback(:create, :after, :add_to_infusionsoft_in_background)
    end

    trait :temporary do
      status { User::TEMPORARY_STATUS }
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

    trait :with_payment_method do
      after(:create) do |user|
        create :payment_method, user: user
      end
    end

    trait :with_site do
      after(:create) do |user|
        create :site, users: [user]
      end
    end
  end
end
