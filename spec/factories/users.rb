FactoryBot.define do
  factory :user do
    transient do
      site nil
    end

    first_name 'FirstName'
    last_name 'LastName'

    sequence(:email) { |i| "user#{ i }@hellobar.com" }
    password 'password'

    after :create do |user, evaluator|
      user.sites << evaluator.site if evaluator.site
    end

    trait :deleted do
      after(:create, &:destroy)
    end

    trait :temporary do
      status { User::TEMPORARY }
    end

    trait :with_free_subscription do
      after(:create) do |user|
        create :subscription, :free, site: evaluator.site || create(:site, user: user)
      end
    end

    trait :with_subscription do
      after(:create) do |user|
        site = create :site, users: [user]
        create :subscription, :free, site: site
      end
    end

    trait :with_pro_subscription do
      after(:create) do |user|
        subscription = create :subscription, :pro
        subscription.credit_card.update user_id: user.id
      end
    end

    trait :with_pro_subscription_and_bill do
      after(:create) do |user|
        subscription = create :subscription, :pro, :with_bill
        subscription.credit_card.update user_id: user.id
      end
    end

    trait :with_pro_managed_subscription do
      after(:create) do |user|
        subscription = create :subscription, :pro_managed
        subscription.credit_card.update user_id: user.id
      end
    end

    trait :with_credit_card do
      after(:create) do |user|
        create :credit_card, user: user
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

    trait :affiliate do
      affiliate_information
    end
  end
end
