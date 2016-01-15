FactoryGirl.define do
  factory :site do
    url { Faker::Internet.url }

    after(:create) do |site|
      create(:rule, site: site)
    end
  end
end
