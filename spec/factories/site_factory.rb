FactoryGirl.define do
  factory :site do
    url { random_uniq_url }

    trait :with_rule do
      after(:create) do |site|
        create(:rule, site: site)
      end
    end
  end
end
