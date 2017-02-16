FactoryGirl.define do
  factory :site_membership do
    role 'owner'
    site
    user

    factory :site_ownership do
      role 'owner'
    end

    factory :site_adminship do
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
