FactoryGirl.define do
  factory :site do
    url { Faker::Internet.url }

    trait :with_rule do
      after(:create) do |site|
        create(:rule, site: site)
      end
    end
  end
end
