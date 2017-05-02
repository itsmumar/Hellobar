FactoryGirl.define do
  factory :user do
    transient do
      site nil
    end

    first_name 'FirstName'
    last_name 'LastName'
    email { generate(:email) }
    password 'password'

    after :create do |user, evaluator|
      if evaluator.site
        user.sites << evaluator.site
      end
    end

    trait :deleted do
      after(:create, &:destroy)
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
        create :payment_method, :success, user: user
      end
    end

    trait :with_site do
      after(:create) do |user|
        create :site, users: [user]
      end
    end

    trait :with_email_bar do
      after(:create) do |user|
        site = create :site, :with_rule, users: [user]
        create :site_element, :email, site: site
      end
    end

    trait :with_sites do
      transient do
        count 1
      end

      after(:create) do |user, evaluator|
        create_list :site, evaluator.count, users: [user]
      end
    end
  end
end
