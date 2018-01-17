FactoryGirl.define do
  factory :campaign do
    site

    contact_list { create :contact_list, site: site }

    sequence(:name) { |i| "Campaign #{ i }" }

    from_name 'Hello Bar'
    from_email 'dev@hellobar.com'
    subject 'Hello'
    body 'Test Campaign'

    trait :new do
      status Campaign::NEW
    end

    trait :sent do
      status Campaign::SENT
      sent_at { Time.current }
    end
  end
end
