FactoryBot.define do
  factory :site_membership do
    role 'owner'
    site
    user

    trait :admin do
      user
      role 'admin'
    end

    trait :with_site_rule do
      role 'owner'
      association :site, :with_rule
      user
    end
  end
end
