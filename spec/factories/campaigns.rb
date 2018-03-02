FactoryBot.define do
  factory :campaign do
    site

    contact_list { create :contact_list, site: site }

    sequence(:name) { |i| "Campaign #{ i }" }

    email

    trait :draft do
      status Campaign::DRAFT
    end

    trait :sending do
      status Campaign::SENDING
    end

    trait :sent do
      status Campaign::SENT
      sent_at { Time.current }
    end

    trait :archived do
      status Campaign::ARCHIVED
    end
  end
end
