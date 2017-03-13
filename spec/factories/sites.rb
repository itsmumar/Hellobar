FactoryGirl.define do
  factory :site do
    url { random_uniq_url }

    trait :with_rule do
      after(:create) do |site|
        create(:rule, site: site)
      end
    end

    trait :with_user do
      after(:create) do |site|
        site.users << create(:user)
      end
    end

    trait :free_subscription do
      after(:create) do |site|
        create(:free_subscription, site: site, user: site.users.first)
      end
    end

    trait :pro do
      after(:create) do |site|
        create(:pro_subscription, site: site, user: site.users.first)
      end
    end
  end
end
