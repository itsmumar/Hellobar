FactoryGirl.define do
  factory :site do
    transient do
      elements []
      user nil
    end

    url { generate(:random_uniq_url) }

    after :create do |site, evaluator|
      create(:rule, site: site) if evaluator.elements.present?

      evaluator.elements.each do |element|
        create(:site_element, element, site: site)
      end

      site.users << evaluator.user if evaluator.user.present?
      site.reload
    end

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
        create(:subscription, :free, site: site, user: site.users.first)
      end
    end

    trait :pro do
      after(:create) do |site|
        create(:subscription, :pro, site: site, user: site.users.first)
      end
    end

    trait :enterprise do
      after(:create) do |site|
        create(:enterprise_subscription, site: site, user: site.users.first)
      end
    end

    trait :pro_managed do
      after(:create) do |site|
        create(:subscription, :pro_managed, site: site, user: site.users.first)
      end
    end

    trait :past_due_site do
      after(:create) do |site|
        subscription = create(:subscription, :pro, site: site, user: site.users.first)
        create(:past_due_bill, subscription: subscription)
      end
    end
  end
end
